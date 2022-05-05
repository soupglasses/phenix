{ ... }:
{
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.example = {
    sopsFile = ./secrets/nona.yaml;
    format = "yaml";
  };
}
