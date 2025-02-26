# Development environment profile
{pkgs, ...}: {
  # Development tools and packages
  home.packages = with pkgs; [
    # Version Control
    git
    git-lfs
    gh

    # Development Tools
    vscode
    direnv
    docker-compose

    # Languages and Runtimes
    nodejs
    python3
    rustup

    # Build Tools
    gnumake
    cmake
    gcc

    # Debug Tools
    gdb
    lldb
  ];

  # Development environment configurations
  programs = {
    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        # Remote Development
        # Note: remote-wsl extension needs to be installed manually through VSCode
        ms-vscode-remote.remote-ssh

        # Languages
        ms-python.python
        rust-lang.rust-analyzer
        golang.go

        # Tools
        vscodevim.vim
        github.copilot
        github.copilot-chat

        # Theme
        github.github-vscode-theme
      ];
      userSettings = {
        "editor.formatOnSave" = true;
        "editor.fontFamily" = "'FiraCode Nerd Font', 'Droid Sans Mono', 'monospace'";
        "editor.fontLigatures" = true;
        "files.autoSave" = "onFocusChange";
        "workbench.colorTheme" = "GitHub Dark Default";
        "terminal.integrated.fontFamily" = "'FiraCode Nerd Font'";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
