{lib, ...}: {
  programs.starship.enable = true;
  programs.starship.settings = builtins.foldl' lib.recursiveUpdate {} [
    {
      add_newline = false;
      format = "$directory$all$character";
      hostname = {
        format = "([@$hostname]($style) )";
        style = "green";
        ssh_only = true;
      };
      directory = {
        style = "blue";
        home_symbol = "~";
        read_only = " ro";
        truncation_symbol = "…/";
        truncation_length = 3;
        truncate_to_repo = true;
      };
      git_branch = {
        format = "[$symbol$branch]($style) ";
        style = "bright-green";
        symbol = "";
      };
      git_status = {
        format = "([$all_status$ahead_behind]($style))";
        style = "dimmed white";
        conflicted = "([~\${count}](red) )";
        ahead = "([⇡\${count}](green) )";
        behind = "([⇣\${count}](green) )";
        diverged = "([⇡\${ahead_count}⇣\${behind_count}](green) )";
        up_to_date = "";
        untracked = "([?\${count}](blue) )";
        stashed = "([*\${count}](green) )";
        modified = "([!\${count}](yellow) )";
        staged = "([+\${count}](yellow) )";
        renamed = "([r\${count}](yellow) )";
        deleted = "([-\${count}](yellow) )";
      };
      jobs.symbol = "j";
      nix_shell = {
        format = "[$symbol( $state)]($style) ";
        style = "purple";
        symbol = "nix";
        impure_msg = "";
        pure_msg = "pure";
      };
      custom.virtualenv = {
        command = ''printf "''${VIRTUAL_ENV:+"venv"}"'';
        description = "Shows when you are in a virtual environment";
        format = "([$output](purple) )";
        when = true;
        shell = "bash";
        disabled = false;
      };
      username.disabled = true;
      sudo.disabled = true;
      custom.sudo = {
        command = ''printf "sudo"'';
        description = "Shows when you have sudo, ignoring the root user and ssh connections.";
        format = "([$output](bright-red) )";
        when = ''[[ -z "$SSH_CONNECTION$SSH_CLIENT$SSH_TTY" ]] && [[ `whoami` != "root" ]] && sudo -n true'';
        shell = "bash";
        disabled = false;
      };
      custom.root = {
        command = ''printf "root"'';
        description = "Shows when you are the root user";
        format = "([$output](bright-red) )";
        when = ''[[ `whoami` == "root" ]]'';
        shell = "bash";
        disabled = false;
      };
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
        min_time = 10000; # 10 seconds
      };
      line_break.disabled = true;
      battery = {
        full_symbol = "";
        charging_symbol = "B";
        discharging_symbol = "B";
        display = [
          {
            threshold = 15;
            style = "red";
          }
          {
            threshold = 25;
            style = "yellow";
          }
        ];
        disabled = false;
      };
      status = {
        format = "[$symbol$status]($style) ";
        style = "red";
        symbol = "E";
        disabled = false;
      };
      character = {
        success_symbol = "[%](dimmed white)";
        error_symbol = "[%](dimmed white)";
        vicmd_symbol = "[V](green)";
      };
    }
    {
      aws.symbol = "aws ";
      cmake.symbol = "cmake ";
      cobol.symbol = "cobol ";
      conda.symbol = "conda ";
      crystal.symbol = "cr ";
      dart.symbol = "dart ";
      deno.symbol = "deno ";
      docker_context.symbol = "docker ";
      dotnet.symbol = ".net ";
      elixir.symbol = "ex ";
      elm.symbol = "elm ";
      golang.symbol = "go ";
      haskell.symbol = "hs ";
      hg_branch.symbol = "hg ";
      java.symbol = "java ";
      julia.symbol = "jl ";
      kotlin.symbol = "kt ";
      memory_usage.symbol = "mem ";
      nim.symbol = "nim ";
      nodejs.symbol = "node ";
      ocaml.symbol = "ml ";
      package.symbol = "pkg ";
      perl.symbol = "pl ";
      php.symbol = "php ";
      pulumi.symbol = "pulumi ";
      purescript.symbol = "purs ";
      python.symbol = "py ";
      ruby.symbol = "rb ";
      rust.symbol = "rs ";
      scala.symbol = "scala ";
      swift.symbol = "swift ";
      vagrant.symbol = "vagrant ";
    }
    {
      aws.disabled = true;
      cmake.disabled = true;
      cobol.disabled = true;
      conda.disabled = true;
      crystal.disabled = true;
      dart.disabled = true;
      deno.disabled = true;
      docker_context.disabled = true;
      dotnet.disabled = true;
      elixir.disabled = true;
      elm.disabled = true;
      golang.disabled = true;
      haskell.disabled = true;
      hg_branch.disabled = true;
      java.disabled = true;
      julia.disabled = true;
      kotlin.disabled = true;
      lua.disabled = true;
      memory_usage.disabled = true;
      nim.disabled = true;
      nodejs.disabled = true;
      ocaml.disabled = true;
      package.disabled = true;
      perl.disabled = true;
      php.disabled = true;
      pulumi.disabled = true;
      purescript.disabled = true;
      python.disabled = true;
      ruby.disabled = true;
      rust.disabled = true;
      scala.disabled = true;
      swift.disabled = true;
      vagrant.disabled = true;
    }
  ];
}
