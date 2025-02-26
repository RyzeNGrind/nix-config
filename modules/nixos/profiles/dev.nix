# Development environment profile
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.profiles.dev;
in {
  imports = [
    ../cursor
  ];

  options.profiles.dev = {
    enable = mkEnableOption "Development environment profile";

    tools = {
      enable = mkEnableOption "Development tools";

      languages = {
        python.enable = mkEnableOption "Python development support";
        node.enable = mkEnableOption "Node.js development support";
        rust.enable = mkEnableOption "Rust development support";
        go.enable = mkEnableOption "Go development support";
      };

      editors = {
        vscode.enable = mkEnableOption "VSCode IDE support";
        cursor.enable = mkEnableOption "Cursor IDE support";
        neovim.enable = mkEnableOption "Neovim editor support";
      };

      containers = {
        enable = mkEnableOption "Container development support";
        docker.enable = mkEnableOption "Docker support";
        podman.enable = mkEnableOption "Podman support";
      };

      cloud = {
        enable = mkEnableOption "Cloud development tools";
        aws.enable = mkEnableOption "AWS development tools";
        azure.enable = mkEnableOption "Azure development tools";
        gcp.enable = mkEnableOption "GCP development tools";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Base development tools
      environment.systemPackages = with pkgs; [
        git
        gh
        gnumake
        gcc
        gdb
        cmake
        ninja
        meson
        pkg-config
      ];
    }

    (mkIf cfg.tools.enable {
      # Additional development tools configuration
      environment.systemPackages = with pkgs; [
        ripgrep
        fd
        jq
        yq
        tree
        htop
        tmux
      ];
    })

    # Language-specific configurations
    (mkIf cfg.tools.languages.python.enable {
      environment.systemPackages = with pkgs; [
        python3
        python3Packages.pip
        python3Packages.virtualenv
        poetry
      ];
    })

    (mkIf cfg.tools.languages.node.enable {
      environment.systemPackages = with pkgs; [
        nodejs_20
        yarn
        nodePackages.pnpm
      ];
    })

    (mkIf cfg.tools.languages.rust.enable {
      environment.systemPackages = with pkgs; [
        rustc
        cargo
        rustfmt
        rust-analyzer
      ];
    })

    (mkIf cfg.tools.languages.go.enable {
      environment.systemPackages = with pkgs; [
        go
        gopls
        delve
      ];
    })

    # Editor configurations
    (mkIf cfg.tools.editors.vscode.enable {
      services.vscode.enable = true;
    })

    (mkIf cfg.tools.editors.cursor.enable {
      services.cursor.enable = true;
    })

    (mkIf cfg.tools.editors.neovim.enable {
      environment.systemPackages = with pkgs; [
        neovim
        tree-sitter
      ];
    })

    # Container support
    (mkIf cfg.tools.containers.enable {
      virtualisation = {
        docker.enable = mkIf cfg.tools.containers.docker.enable true;
        podman.enable = mkIf cfg.tools.containers.podman.enable true;
      };
    })

    # Cloud tools
    (mkIf cfg.tools.cloud.enable {
      environment.systemPackages = with pkgs;
        [
          terraform
          kubectl
          kubernetes-helm
        ]
        ++ (optionals cfg.tools.cloud.aws.enable [
          awscli2
          ssm-session-manager-plugin
        ])
        ++ (optionals cfg.tools.cloud.azure.enable [
          azure-cli
        ])
        ++ (optionals cfg.tools.cloud.gcp.enable [
          google-cloud-sdk
        ]);
    })
  ]);
}
