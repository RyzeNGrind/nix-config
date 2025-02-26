# Shell customization profile
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.shell;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Shell utilities
      ripgrep
      fd
      fzf
      bat
      eza
      zoxide
      jq
      yq

      # System monitoring
      htop
      btop
      neofetch

      # Terminal multiplexer
      tmux
    ];

    programs = {
      bash = lib.mkIf cfg.bash.enable {
        enable = true;
        enableCompletion = cfg.bash.enableCompletion;
        shellAliases = {
          # Better defaults
          ls = "eza";
          ll = "eza -la";
          cat = "bat";
          find = "fd";
          grep = "rg";

          # Navigation
          ".." = "cd ..";
          "..." = "cd ../..";

          # Git shortcuts
          g = "git";
          ga = "git add";
          gc = "git commit";
          gp = "git push";
          gs = "git status";
        };

        initExtra = ''
          eval "$(starship init bash)"
          eval "$(zoxide init bash)"
          eval "$(direnv hook bash)"
        '';
      };

      fish = lib.mkIf cfg.fish.enable {
        enable = true;
        shellAliases = {
          # Better defaults
          ls = "eza";
          ll = "eza -la";
          cat = "bat";
          find = "fd";
          grep = "rg";

          # Navigation
          ".." = "cd ..";
          "..." = "cd ../..";

          # Git shortcuts
          g = "git";
          ga = "git add";
          gc = "git commit";
          gp = "git push";
          gs = "git status";
        };

        interactiveShellInit = ''
          set -g fish_greeting
          fish_add_path ~/.local/bin
          fish_add_path /run/wrappers/bin
          fish_add_path /nix/var/nix/profiles/default/bin
          fish_add_path /run/current-system/sw/bin

          starship init fish | source
          zoxide init fish | source
          direnv hook fish | source
        '';
      };

      # Shell prompt
      starship = {
        enable = true;
        enableBashIntegration = cfg.bash.enable;
        enableFishIntegration = cfg.fish.enable;
      };

      # Directory jumping
      zoxide = {
        enable = true;
        enableBashIntegration = cfg.bash.enable;
        enableFishIntegration = cfg.fish.enable;
      };

      # Directory environment
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      tmux = {
        enable = true;
        shortcut = "a";
        terminal = "screen-256color";
        historyLimit = 10000;
        plugins = with pkgs.tmuxPlugins; [
          sensible
          yank
          resurrect
          continuum
        ];
        extraConfig = ''
          # Enable mouse support
          set -g mouse on

          # Start windows and panes at 1, not 0
          set -g base-index 1
          setw -g pane-base-index 1

          # Automatically set window title
          set-window-option -g automatic-rename on
          set-option -g set-titles on
        '';
      };
    };
  };
}
