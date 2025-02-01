{ config, lib, pkgs, ... }:

{
  # WSL-specific home configuration
  home.sessionVariables = {
    WSLENV = "NIXOS_WSL";
    BROWSER = "wslview";
    DISPLAY = ":0";
  };

  # WSL-specific program configurations
  programs = {
    bash = {
      initExtra = ''
        # WSL-specific bash configuration
        if [ -n "$NIXOS_WSL" ]; then
          # Integration with Windows clipboard
          alias pbcopy="clip.exe"
          alias pbpaste="powershell.exe -command 'Get-Clipboard' | tr -d '\r'"
          
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
        fi
      '';
    };

    # VSCode WSL configuration if needed
    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        ms-vscode-remote.remote-wsl
      ];
    };
  };

  # WSL-specific XDG configuration
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps.enable = true;
  };
} 