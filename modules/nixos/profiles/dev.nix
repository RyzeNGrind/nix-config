{ config, lib, pkgs, ... }:

{
  options.profiles.dev = {
    enable = lib.mkEnableOption "Development environment profile";
    ide = lib.mkOption {
      type = lib.types.enum [ "vscode" "vscodium" "neovim" "cursor" ];
      default = "vscodium";
      description = "Primary IDE to use";
    };
    vscodeRemote = {
      enable = lib.mkEnableOption "VSCode Remote support";
      method = lib.mkOption {
        type = lib.types.enum [ "nix-ld" "patch" ];
        default = "nix-ld";
        description = "Method to enable VSCode Remote support (nix-ld or patch)";
      };
    };
  };

  config = lib.mkIf config.profiles.dev.enable {
    environment.systemPackages = with pkgs; [
      # Version Control
      git
      git-lfs
      gh

      # Build tools
      gnumake
      cmake
      ninja

      # Development tools
      direnv
      nix-direnv
      wget # Required for VSCode Remote

      # Debugging and profiling
      gdb
      lldb
      strace
      ltrace

      # IDE and editor
      (lib.mkIf (config.profiles.dev.ide == "vscode") vscode)
      (lib.mkIf (config.profiles.dev.ide == "vscodium") 
        (vscode-with-extensions.override {
          vscode = vscodium;
          vscodeExtensions = with pkgs.vscode-extensions; [
            # Development
            ms-vscode.cpptools
            ms-python.python
            ms-vscode.cmake-tools
            
            # Remote Development
            ms-vscode-remote.remote-ssh
            
            # Git
            eamodio.gitlens
            
            # Nix
            bbenoist.nix
            jnoortheen.nix-ide
            arrterian.nix-env-selector
            
            # Theme and UI
            pkief.material-icon-theme
          ];
        })
      )
      (lib.mkIf (config.profiles.dev.ide == "neovim") neovim)

      # Language servers and formatters
      nil # Nix LSP
      nixpkgs-fmt
      alejandra
      statix # Nix static analysis
    ];

    # VSCode Remote support configuration
    programs.nix-ld = lib.mkIf (config.profiles.dev.vscodeRemote.enable && config.profiles.dev.vscodeRemote.method == "nix-ld") {
      enable = true;
      package = pkgs.nix-ld-rs;
    };

    # If using patch method, include the vscode-remote-workaround module
    vscode-remote-workaround.enable = lib.mkIf (config.profiles.dev.vscodeRemote.enable && config.profiles.dev.vscodeRemote.method == "patch") true;

    # Development environment configuration
    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };

    # Nix development settings
    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" "repl-flake" ];
        warn-dirty = false;
        keep-outputs = true;
        keep-derivations = true;
      };
    };
  };
} 