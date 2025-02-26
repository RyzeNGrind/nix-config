# Development features module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.core.features;
in {
  options.core.features = with lib; {
    development = {
      enable = mkEnableOption "Development tools and environments";

      tools = {
        enable = mkEnableOption "Common development tools";
        nix = mkEnableOption "Nix development tools";
        shell = mkEnableOption "Shell development tools";
        containers = {
          enable = mkEnableOption "Container development support";
          docker = {
            enable = mkEnableOption "Docker support";
            compose = mkEnableOption "Docker Compose support";
          };
          podman = {
            enable = mkEnableOption "Podman support";
            compose = mkEnableOption "Podman Compose support";
          };
        };
      };

      ide = {
        enable = mkEnableOption "IDE support";
        vscode = {
          enable = mkEnableOption "VSCode support";
          remote = mkEnableOption "VSCode Remote support";
        };
        cursor = {
          enable = mkEnableOption "Cursor IDE support";
          remote = mkEnableOption "Cursor Remote support";
        };
      };

      languages = {
        python = mkEnableOption "Python development support";
        rust = mkEnableOption "Rust development support";
        go = mkEnableOption "Go development support";
        node = mkEnableOption "Node.js development support";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.development.enable {
      # Basic development tools
      environment.systemPackages = with pkgs; [
        git
        git-lfs
        gnumake
        cmake
        gcc
        binutils
      ];
    })

    (lib.mkIf cfg.development.tools.enable {
      environment.systemPackages = with pkgs; [
        ripgrep
        fd
        jq
        yq
        curl
        wget
        htop
        btop
      ];
    })

    (lib.mkIf cfg.development.tools.nix {
      environment.systemPackages = with pkgs; [
        nixpkgs-fmt
        nil
        statix
        nix-prefetch-git
        nix-prefetch-github
        nix-index
        nix-tree
      ];
    })

    (lib.mkIf cfg.development.tools.shell {
      environment.systemPackages = with pkgs; [
        shellcheck
        shfmt
        bash-completion
        fish
        starship
      ];
    })

    (lib.mkIf cfg.development.tools.containers.enable (lib.mkMerge [
      # Docker support
      (lib.mkIf cfg.development.tools.containers.docker.enable {
        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
          autoPrune.enable = true;
        };
        environment.systemPackages = with pkgs;
          [
            docker-client
            lazydocker
          ]
          ++ lib.optionals cfg.development.tools.containers.docker.compose [
            docker-compose
          ];
        # Add docker group to all users that have user.docker = true
        users.groups.docker.members =
          builtins.filter
          (user: config.users.users.${user}.docker or false)
          (builtins.attrNames config.users.users);
      })

      # Podman support
      (lib.mkIf cfg.development.tools.containers.podman.enable {
        virtualisation.podman = {
          enable = true;
          dockerCompat = true;
          defaultNetwork.settings.dns_enabled = true;
        };
        environment.systemPackages = with pkgs; [
          podman-compose
        ];
      })
    ]))

    (lib.mkIf cfg.development.ide.vscode.enable {
      environment.systemPackages = with pkgs; [
        vscode
      ];
    })

    (lib.mkIf cfg.development.ide.cursor.enable {
      # Note: Cursor IDE needs to be installed manually from https://cursor.sh
      # as it's not available in nixpkgs
      environment.systemPackages = with pkgs; [
        # Required dependencies for Cursor
        git
        nodejs
      ];
    })

    (lib.mkIf cfg.development.languages.python {
      environment.systemPackages = with pkgs; [
        python3Full
        poetry
        black
        pylint
        mypy
      ];
    })

    (lib.mkIf cfg.development.languages.rust {
      environment.systemPackages = with pkgs; [
        rustup
        rust-analyzer
        cargo-edit
        cargo-watch
      ];
    })

    (lib.mkIf cfg.development.languages.go {
      environment.systemPackages = with pkgs; [
        go
        gopls
        delve
      ];
    })

    (lib.mkIf cfg.development.languages.node {
      environment.systemPackages = with pkgs; [
        nodejs
        yarn
        nodePackages.pnpm
        nodePackages.typescript
        nodePackages.typescript-language-server
      ];
    })
  ];
}
