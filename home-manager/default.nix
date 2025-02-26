# Default home-manager configuration
{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../modules/home-manager/profiles
  ];

  # Basic home-manager configuration
  home = {
    # State version should match the NixOS version
    stateVersion = "24.05";

    # Basic packages that should be available everywhere
    packages = with pkgs; [
      # Core utilities
      curl
      wget
      file
      p7zip
      nix-bash-completions
    ];

    # Common environment variables
    sessionVariables = {
      EDITOR = "code";
      VISUAL = "code";
      BROWSER = "wsl-open";
      TERMINAL = "waveterm";
      PATH = "$HOME/.local/bin:$PATH";
    };
  };

  # Common program configurations
  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };

    bash = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
        ".." = "cd ..";
        "..." = "cd ../..";
      };
    };

    fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting
        starship init fish | source
      '';
    };

    starship = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      settings = {
        add_newline = false;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };
        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
        };
        git_branch = {
          symbol = "🌱 ";
          truncation_length = 20;
        };
        nix_shell = {
          symbol = "❄️ ";
          format = "via [$symbol$state( \($name\))]($style) ";
        };
      };
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
