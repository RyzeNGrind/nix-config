# Host-specific home configuration for daimyo with specialisation support
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ../../modules/home-manager/wsl.nix # Import our WSL module
    inputs.hyprland.homeManagerModules.default
  ];

  home = {
    username = "ryzengrind";
    homeDirectory = "/home/ryzengrind";
    stateVersion = "24.05";

    # Shell integration for 1Password
    sessionVariables = {
      SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
    };

    # Packages configuration
    packages = lib.mkMerge [
      # Common packages across all specialisations
      (with pkgs; [
        # Development tools
        git
        gh
        direnv
        nix-direnv
        pre-commit
        nodePackages.prettier
        black # Python formatting
        alejandra # Nix formatting
        statix # Nix static analysis
        deadnix # Finding dead code
        shellcheck # Shell script analysis

        # Build tools
        gcc
        gnumake
        cargo
        rustc

        # System tools
        htop
        btop
        iotop

        # Network tools
        curl
        wget
        dig
        whois

        # Terminal utilities
        tmux
        fzf
        ripgrep
        fd
        jq
        yq

        # 1Password CLI
        _1password
      ])

      # CUDA specialisation packages
      (lib.mkIf (config.system.nixos.tags or [] == ["wsl-cuda"]) (with pkgs; [
        cudaPackages.cuda_nvcc
        cudaPackages.cuda_cupti
        cudaPackages.cudnn
        nvtop
      ]))

      # Baremetal specialisation packages
      (lib.mkIf (config.system.nixos.tags or [] == ["baremetal"]) (with pkgs; [
        # GUI applications
        firefox
        chromium
        vlc
        # System monitoring
        gnome.gnome-system-monitor
        powertop
        # Hyprland utilities
        waybar
        wofi
        dunst
        swaylock
        swayidle
        grim
        slurp
        wl-clipboard
      ]))
    ];
  };

  # Consolidated program configurations
  programs = {
    # Enable home-manager
    home-manager.enable = true;

    # SSH configuration
    ssh = {
      enable = true;
      extraConfig = ''
        Host *
          IdentityAgent ~/.1password/agent.sock
      '';
    };

    # Git configuration
    git = {
      enable = true;
      userName = "ryzengrind";
      userEmail = "ryzengrind@daimyo.local";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
      package = pkgs.git;
    };

    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        ll = "ls -la";
        ".." = "cd ..";
        "..." = "cd ../..";
        # Specialisation-aware rebuild commands
        "rebuild-cuda" = "sudo nixos-rebuild switch --flake .#daimyo --specialisation wsl-cuda";
        "rebuild-nocuda" = "sudo nixos-rebuild switch --flake .#daimyo --specialisation wsl-nocuda";
        "rebuild-baremetal" = "sudo nixos-rebuild switch --flake .#daimyo --specialisation baremetal";
        update = "nix flake update";
      };
      # Add specialisation detection to bashrc
      initExtra = ''
        # Detect current specialisation
        if [[ -e /run/current-system/specialisation ]]; then
          current_spec=$(readlink /run/current-system/specialisation)
          PS1="\[\033[01;32m\][\u@\h:''${current_spec##*/}]\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
        else
          PS1="\[\033[01;32m\][\u@\h]\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
        fi

        # Set environment based on specialisation
        if [[ "''${current_spec}" == *"wsl-cuda"* ]]; then
          # CUDA environment setup
          export CUDA_PATH="${pkgs.cudaPackages.cudatoolkit}"
          export CUDA_HOME="$CUDA_PATH"
          export PATH="$PATH:$CUDA_HOME/bin"
          export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/lib64"
        fi
      '';
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    vim = {
      enable = true;
      extraConfig = ''
        set number
        set relativenumber
        set expandtab
        set tabstop=2
        set shiftwidth=2
        syntax on
      '';
    };

    # Add VSCode with specialisation-specific extensions
    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions;
        [
          # Common extensions
          bbenoist.nix
          jnoortheen.nix-ide
          mkhl.direnv
          ms-vscode.cpptools
          ms-python.python

          # Conditional CUDA extensions
          (lib.mkIf (config.system.nixos.tags or [] == ["wsl-cuda"])
            nvidia.nsight-vscode-edition)
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          # Add any marketplace extensions here
        ];
    };
  };

  # Enable fonts in home-manager
  fonts.fontconfig.enable = true;

  # Hyprland configuration
  wayland.windowManager.hyprland = lib.mkIf (config.system.nixos.tags or [] == ["baremetal"]) {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    package = null;
    portalPackage = null;
    settings = {
      "$mod" = "SUPER";
      bind = [
        "$mod, Return, exec, alacritty"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, E, exec, pcmanfm"
        "$mod, V, togglefloating"
        "$mod, R, exec, wofi --show drun"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
      ];
      monitor = [
        ",preferred,auto,1"
      ];
      exec-once = [
        "waybar"
        "dunst"
        "hyprctl dispatch dpms on"
      ];
    };
    extraConfig = ''
      # Screen locking
      bind = $mod, L, exec, loginctl lock-session

      # Idle configuration
      exec-once = hypridle

      general {
        lock_cmd = hyprlock
        before_sleep_cmd = hyprlock
        after_sleep_cmd = hyprctl dispatch dpms on
      }

      listener {
        timeout = 300
        on-timeout = hyprlock
      }

      listener {
        timeout = 600
        on-timeout = systemctl suspend
      }
    '';
  };
}
