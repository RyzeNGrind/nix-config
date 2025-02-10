_: {
  # WSL-specific home configuration
  home.sessionVariables = {
    WSLENV = "NIXOS_WSL";
    BROWSER = "wslview";
    DISPLAY = ":0";
    # VSCode Remote settings
    VSCODE_WSL_EXT_LOCATION = "$HOME/.vscode-server/extensions";
    DONT_PROMPT_WSL_INSTALL = "1";
  };

  # WSL-specific program configurations
  programs = {
    bash = {
      initExtra = ''
        # WSL-specific bash configuration
        if [ -n "$NIXOS_WSL" ]; then
          # Integration with Windows clipboard
          if command -v clip.exe >/dev/null 2>&1; then
            alias pbcopy="clip.exe"
            alias pbpaste="powershell.exe -command 'Get-Clipboard' | tr -d '\r'"
          else
            alias pbcopy="xclip -selection clipboard"
            alias pbpaste="xclip -selection clipboard -o"
          fi

          # Windows integration aliases
          alias explorer="explorer.exe"
          alias cmd="cmd.exe"
          alias powershell="powershell.exe"

          # Path conversion helpers
          wslpath() {
            if [ $# -eq 0 ]; then
              echo "Usage: wslpath [-u|-w] path"
              return 1
            fi
            case $1 in
              -w)
                wslpath.exe -w "$2"
                ;;
              -u)
                wslpath.exe -u "$2"
                ;;
              *)
                wslpath.exe "$1"
                ;;
            esac
          }

          # VSCode Remote helper
          code() {
            if [ $# -eq 0 ]; then
              command code .
            else
              command code "$@"
            fi
          }
        fi
      '';
    };
  };

  # WSL-specific XDG configuration
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps.enable = true;
  };
}
