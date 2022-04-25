{ pkgs
, lib
, # The NixOS configuration to be installed onto the disk image.
  config

, # The size of the disk, in megabytes.
  diskSize ? 8192

, # size of the boot partition, is only used if partitionTableType is
  # either "efi" or "hybrid"
  bootSize ? 512

, # The files and directories to be placed in the target file system.
  # This is a list of attribute sets {source, target} where `source'
  # is the file system object (regular file or directory) to be
  # grafted in the file system at path `target'.
  contents ? []

, # The initial NixOS configuration file to be copied to
  # /etc/nixos/configuration.nix.
  configFile ? null

, # Shell code executed after the VM has finished.
  postVM ? ""

, name ? "nixos-disk-image"

, # Disk image format, one of qcow2, qcow2-compressed, vdi, vpc, raw.
  format ? "raw"

, # Include a copy of Nixpkgs in the disk image
  includeChannel ? true
, ...
}:
let
  formatOpt = if format == "qcow2-compressed" then "qcow2" else format;

  compress = lib.optionalString (format == "qcow2-compressed") "-c";

  filename = "nixos." + {
    qcow2 = "qcow2";
    vdi = "vdi";
    vpc = "vhd";
    raw = "img";
  }.${formatOpt} or formatOpt;

  channelSources =
    let
      nixpkgs = lib.cleanSource pkgs.path;
    in
      pkgs.runCommand "nixos-${config.system.nixos.version}" {} ''
        mkdir -p $out
        cp -prd ${nixpkgs.outPath} $out/nixos
        chmod -R u+w $out/nixos
        if [ ! -e $out/nixos/nixpkgs ]; then
          ln -s . $out/nixos/nixpkgs
        fi
        rm -rf $out/nixos/.git
        echo -n ${config.system.nixos.versionSuffix} > $out/nixos/.version-suffix
      '';

  closureInfo = pkgs.closureInfo {
    rootPaths = [ config.system.build.toplevel ]
    ++ (lib.optional includeChannel channelSources);
  };

  modulesTree = pkgs.aggregateModules
    (with config.boot.kernelPackages; [ kernel ]);

  tools = lib.makeBinPath (
    with pkgs; [
      config.system.build.nixos-enter
      config.system.build.nixos-install
      dosfstools
      e2fsprogs
      nix
      parted
      utillinux
    ]
  );

  stringifyProperties = prefix: properties: lib.concatStringsSep " \\\n" (
    lib.mapAttrsToList
      (
        property: value: "${prefix} ${lib.escapeShellArg property}=${lib.escapeShellArg value}"
      )
      properties
  );

  image = (
    pkgs.vmTools.override {
      rootModules =
        [ "9p" "9pnet_virtio" "virtio_pci" "virtio_blk" "rtc_cmos" ];
      kernel = modulesTree;
    }
  ).runInLinuxVM (
    pkgs.runCommand name
      {
        preVM = ''
          PATH=$PATH:${pkgs.qemu_kvm}/bin
          mkdir $out
          diskImage=nixos.raw
          qemu-img create -f raw $diskImage ${toString diskSize}M
        '';

        postVM = ''
          ${if formatOpt == "raw" then ''
          mv $diskImage $out/${filename}
        '' else ''
          ${pkgs.qemu}/bin/qemu-img convert -f raw -O ${formatOpt} ${compress} $diskImage $out/${filename}
        ''}
          diskImage=$out/${filename}
          ${postVM}
        '';
      } ''
      export PATH=${tools}:$PATH
      set -x

      cp -sv /dev/vda /dev/sda
      cp -sv /dev/vda /dev/xvda

      parted --script /dev/vda -- \
        mklabel gpt \
        mkpart no-fs 1MB 2MB \
        align-check optimal 1 \
        set 1 bios_grub on \
        mkpart ESP fat32 8MB ${toString bootSize}MB \
        align-check optimal 2 \
        set 2 boot on \
        mkpart primary ${toString bootSize}MB -1 \
        align-check optimal 3 \
        print

      mkdir /mnt
      mount -t tmpfs none /mnt

      mkdir -p /mnt/{boot,nix,etc/{nixos,ssh},var/{lib,log},srv}

      mkdir -p /mnt/boot
      mkfs.vfat /dev/vda2 -n ESP
      mount -t vfat /dev/vda2 /mnt/boot

      mkfs.ext4 -L nix /dev/vda3
      mount /dev/vda3 /mnt/nix

      mkdir -p /mnt/nix/persist/{etc/{nixos,ssh},var/{lib,log},srv}

      mount -o bind /mnt/nix/persist/etc/nixos /mnt/etc/nixos
      mount -o bind /mnt/nix/persist/var/lib /mnt/var/lib
      mount -o bind /mnt/nix/persist/var/log /mnt/var/log

      mount

      # Install a configuration.nix
     mkdir -p /mnt/etc/nixos
      # `cat` so it is mutable on the fs
      ${lib.optionalString (configFile != null) ''
        cat ${configFile} > /mnt/etc/nixos/configuration.nix
      ''}

      export NIX_STATE_DIR=$TMPDIR/state
      nix-store --load-db < ${closureInfo}/registration

      echo copying toplevel
      time nix --extra-experimental-features nix-command copy --no-check-sigs --to 'local?root=/mnt/' ${config.system.build.toplevel}

      ${lib.optionalString includeChannel ''
        echo copying channels
        time nix --extra-experimental-features nix-command copy --no-check-sigs --to 'local?root=/mnt/' ${channelSources}
      ''}

      echo installing bootloader
      time nixos-install --root /mnt --no-root-passwd \
        --system ${config.system.build.toplevel} \
        --substituters " " ${lib.optionalString includeChannel "--channel ${channelSources}"}

      df -h
      umount /mnt/boot
    ''
  );
in
image 
