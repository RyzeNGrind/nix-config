{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    ../../modules/home-manager/wsl.nix  # Common WSL home-manager configurations
  ];

  home = {
    username = "ryzengrind";
    homeDirectory = "/home/ryzengrind";
    stateVersion = "24.05";
    
    packages = with pkgs; [
      # Development tools
      git
      gh
      direnv
      nix-direnv
      
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
    ];
  };

  programs = {
    home-manager.enable = true;
    
    git = {
      enable = true;
      userName = "ryzengrind";
      userEmail = "ryzengrind@daimyo00.local";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
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
      initExtra = ''
        # Custom bash initialization
        export EDITOR=vim
        export PATH=$HOME/.local/bin:$PATH
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
  };

  # Enable fonts in home-manager
  fonts.fontconfig.enable = true;
} 