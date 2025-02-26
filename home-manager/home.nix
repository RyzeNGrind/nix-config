# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  config,
  pkgs,
  inputs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix

    # Import upstream modules as needed
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      permittedInsecurePackages = [
        "python3.10-certifi-2022.9.24"
      ];
    };
  };

  # Basic configuration
  home = {
    username = "ryzengrind";
    homeDirectory = "/home/ryzengrind";
    stateVersion = "24.05";

    # Basic utilities that don't belong in profiles
    packages = with pkgs; [
      curl
      wget
      file
      p7zip
      nix-bash-completions
    ];

    sessionVariables = {
      EDITOR = "code";
      VISUAL = "code";
      BROWSER = "wsl-open";
      TERMINAL = "waveterm";
      PATH = "$HOME/.local/bin:$PATH";
    };
  };

  # Enable profiles based on system role
  profiles = {
    dev = {
      enable = true;
      ide = "vscodium";
      vscodeRemote = {
        enable = true;
        method = "nix-ld";
      };
      tools = {
        enable = true;
        nix = true;
        shell = true;
      };
    };
    desktop = {
      enable = true;
      apps = {
        browsers.enable = true;
        communication.enable = true;
        media.enable = true;
        remote-tools = {
          enable = true;
          termius.enable = true;
          synergy.enable = true;
          remote-desktop.enable = true;
        };
      };
      wm.hyprland.enable = true;
    };
    security = {
      enable = true;
      vpn = {
        enable = true;
        proton.enable = true;
        tailscale.enable = true;
        zerotier.enable = true;
      };
      tools = {
        enable = true;
        onepassword.enable = true;
        tor.enable = true;
        v2ray.enable = true;
      };
    };
  };

  # Basic program configurations
  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "ryzengrind";
      userEmail = "ryzengrind@gmail.com";
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
