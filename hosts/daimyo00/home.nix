# Host-specific home configuration for daimyo00
{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:

let
  scripts = pkgs.callPackage ../../pkgs/scripts { };
in
{
  imports = [
    ../../modules/home-manager/wsl.nix # Import our WSL module
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
      gcc
      rustc
      cargo
      pkg-config
      gnumake

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
      nixfmt-rfc-style
      statix
      deadnix
      nix-ld

      # VSCodium cursor server setup
      scripts.vscodiumCursorServer

      # Update 1Password package configuration
      (writeShellScriptBin "1p" ''
        nohup ${pkgs._1password-gui}/bin/1password --silent > /dev/null 2>&1 &
      '')
    ];

    # Create the pre-commit hook file
    file.".config/git/hooks/pre-commit" = {
      executable = true;
      text = builtins.readFile (scripts.preCommitHook + "/bin/pre-commit-hook");
    };

    # Create the hooks directory
    file.".config/git/hooks/.keep".text = "";
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
        core.hooksPath = "${config.xdg.configHome}/git/hooks";
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
        "1password" = "1p"; # Add alias for 1password
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

    vscode = {
      enable = true;
      package = pkgs.vscodium; # Switch to VSCodium
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        # Nix support
        bbenoist.nix
        jnoortheen.nix-ide
        brettm12345.nixfmt-vscode

        # Git integration
        eamodio.gitlens
        mhutchie.git-graph

        # Remote development
        ms-vscode-remote.remote-ssh

        # General development
        ms-azuretools.vscode-docker
        redhat.vscode-yaml
        yzhang.markdown-all-in-one

        # Theme and UI
        pkief.material-icon-theme

        # Editor enhancements
        editorconfig.editorconfig
        esbenp.prettier-vscode

        # AI assistance
        github.copilot
      ];

      userSettings = {
        "editor.fontFamily" = "'FiraCode Nerd Font', 'Droid Sans Mono', 'monospace'";
        "editor.fontSize" = 14;
        "editor.formatOnSave" = true;
        "editor.rulers" = [
          80
          120
        ];
        "editor.renderWhitespace" = "boundary";
        "editor.suggestSelection" = "first";
        "editor.bracketPairColorization.enabled" = true;

        "workbench.colorTheme" = "Default Dark Modern";
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.startupEditor" = "none";

        "files.autoSave" = "onFocusChange";
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;

        "terminal.integrated.fontFamily" = "'FiraCode Nerd Font'";
        "terminal.integrated.fontSize" = 14;

        "git.enableSmartCommit" = true;
        "git.autofetch" = true;

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";

        "[nix]" = {
          "editor.tabSize" = 2;
          "editor.formatOnSave" = true;
        };

        # VSCodium-specific settings for cursor server
        "remote.SSH.remotePlatform" = {
          "localhost" = "linux";
        };
        "remote.SSH.useLocalServer" = true;
        "remote.SSH.enableDynamicForwarding" = true;
        "remote.SSH.enableRemoteCommand" = true;
      };
    };
  };

  # Enable fonts in home-manager
  fonts.fontconfig.enable = true;
}
