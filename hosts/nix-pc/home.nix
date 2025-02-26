# Home configuration for Surface Book 3
{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: {
  imports = [
    ../../modules/home-manager/profiles
  ];

  # Enable profile-based configuration
  profiles = {
    enable = true;

    development = {
      enable = true;
      ide = {
        enable = true;
        vscode.enable = true;
        cursor.enable = true;
      };
    };

    desktop = {
      enable = true;
      apps = {
        browsers.enable = true;
        communication.enable = true;
      };
    };
  };

  # Host-specific configuration
  home = {
    username = "ryzengrind";
    homeDirectory = "/home/ryzengrind";
    stateVersion = "24.05";

    # Host-specific packages
    packages = with pkgs; [
      # WSL utilities
      wslu
      wsl-open

      # System tools
      htop
      btop
      neofetch

      # Development tools
      vscode
      git
      gh
      direnv

      # Additional tools specific to Surface Book 3 workflow
      docker-compose
      nodejs
      python3

      # Nix tools
      nixfmt-rfc-style
      nix-index
      nix-prefetch-git
      nix-prefetch-scripts
      nix-prefetch-github
      nix-prefetch-docker
      alejandra
      nixd

      # Fonts
      monaspace
      fira-code
      fira-code-nerdfont
      jetbrains-mono
      nerdfonts
      nerdfetch

      # AI tools
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.aider-chat
    ];

    # Host-specific environment variables
    sessionVariables = {
      EDITOR = "code";
      VISUAL = "code";
      BROWSER = "wsl-open";
    };
  };

  # Disable dconf for WSL environment
  dconf.enable = false;

  # Configure nixpkgs
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg:
      builtins.elem (pkgs.lib.getName pkg) [
        "vscode"
        "vscode-extensions"
        "discord"
        "teamviewer"
        "synergy"
        "1password"
        "1password-gui"
      ];
  };

  # Program configurations
  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      userName = "RyzeNGrind";
      userEmail = "ryzengrind@nix-pc.local";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };

    # Bash shell configuration
    bash = {
      enable = true;
      enableCompletion = true;
      
      initExtra = ''
        # Add paths
        export PATH="$HOME/.local/bin:$PATH"
        export PATH="/run/wrappers/bin:$PATH"
        export PATH="/nix/var/nix/profiles/default/bin:$PATH"
        export PATH="/run/current-system/sw/bin:$PATH"

        # Set environment variables
        export SHELL=$(command -v bash)
        export EDITOR=vim
        export VISUAL=code
        export PAGER=less
        export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:$HOME/.nix-defexpr/channels"
        export NIX_PROFILES="/nix/var/nix/profiles/default /run/current-system/sw $HOME/.nix-profile"
        export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

        # Initialize tools if available
        if command -v starship >/dev/null; then
          eval "$(starship init bash)"
        fi

        if command -v zoxide >/dev/null; then
          eval "$(zoxide init bash)"
        fi

        if command -v direnv >/dev/null; then
          eval "$(direnv hook bash)"
        fi

        # Set up fallback commands first
        alias ls='/run/current-system/sw/bin/ls'
        alias cat='/run/current-system/sw/bin/cat'
        alias grep='/run/current-system/sw/bin/grep'
        alias find='/run/current-system/sw/bin/find'

        # Then override with modern alternatives if available
        if command -v eza >/dev/null; then
          alias ls='eza'
          alias ll='eza -l'
          alias la='eza -la'
        fi

        if command -v bat >/dev/null; then
          alias cat='bat'
        fi

        if command -v fd >/dev/null; then
          alias find='fd'
        fi

        if command -v rg >/dev/null; then
          alias grep='rg'
        fi

        # Nix-specific aliases
        if command -v nixos-rebuild >/dev/null; then
          alias rebuild='sudo nixos-rebuild switch --flake .#'
        fi

        if command -v nix >/dev/null; then
          alias build='nix build'
          alias develop='nix develop'
          alias search='nix search'
          alias shell='nix shell'
          alias run='nix run'
        fi

        # Navigation aliases
        alias ".."="cd .."
        alias "..."="cd ../.."

        # Git shortcuts
        alias g="git"
        alias ga="git add"
        alias gc="git commit"
        alias gp="git push"
        alias gs="git status"
      '';
    };

    # Starship configuration
    starship = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        add_newline = true;
        command_timeout = 5000;

        # Git configuration
        git_status = {
          format = "[$all_status$ahead_behind]($style) ";
          ahead = "⇡$count";
          behind = "⇣$count";
          diverged = "⇕⇡$ahead_count⇣$behind_count";
          untracked = "?$count";
          stashed = "$\$count";
          modified = "!$count";
          staged = "+$count";
          renamed = "»$count";
          deleted = "✘$count";
          style = "bold purple";
          disabled = false;
        };

        # Git branch settings
        git_branch = {
          format = "[$symbol$branch]($style) ";
          style = "bold purple";
          disabled = false;
        };

        # Git commit settings
        git_commit = {
          format = "[\\($hash\\)]($style) ";
          style = "bold green";
          disabled = false;
        };

        # Git state settings
        git_state = {
          format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
          style = "bold yellow";
          disabled = false;
        };

        # Disable git metrics for performance
        git_metrics = {
          disabled = true;
        };

        # WSL-specific settings
        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
          vicmd_symbol = "[❮](bold blue)";
        };

        directory = {
          truncation_length = 5;
          format = "[$path]($style)[$read_only]($read_only_style) ";
        };

        # WSL detection
        env_var.WSL_DISTRO_NAME = {
          format = "[$env_value]($style) ";
          style = "bold cyan";
        };
      };
    };

    # Directory jumping
    zoxide = {
      enable = true;
      enableBashIntegration = true;
    };

    # Directory environment
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
