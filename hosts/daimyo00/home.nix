# Host-specific home configuration for daimyo00
{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    ../../modules/home-manager/wsl.nix  # Import our WSL module
  ];

  # Basic home-manager settings
  home = {
    username = "ryzengrind";
    homeDirectory = "/home/ryzengrind";
    stateVersion = "24.05";
    
    # Host-specific packages
    packages = with pkgs; [
      # Development tools
      git
      gh
      direnv
      nix-direnv
      pre-commit
      
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

      # IDE utilities
      pre-commit
      _1password-gui
      nixfmt
      nixld
      
    ];
  };

  # Enable home-manager
  programs.home-manager.enable = true;

  # Host-specific program configurations
  programs = {
    git = {
      enable = true;
      userName = "ryzengrind";
      userEmail = "ryzengrind@daimyo00.local";
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
        rebuild = "sudo nixos-rebuild switch --flake .#daimyo00";
        update = "nix flake update";
      };
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

/*     pre-commit = {
      enable = true;
      hooks = {
        nixpkgs-fmt.enable = true;
        prettier.enable = true;
        black.enable = true;
      };
    }; */
  };

  # Enable fonts in home-manager
  fonts.fontconfig.enable = true;
} 