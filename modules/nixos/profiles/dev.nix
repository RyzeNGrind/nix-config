{ config, lib, pkgs, ... }:

{
  options.profiles.dev = {
    enable = lib.mkEnableOption "Development environment profile";
    ide = lib.mkOption {
      type = lib.types.enum [ "vscode" "vscodium" "neovim" ];
      default = "vscode";
      description = "Primary IDE to use";
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

      # Debugging and profiling
      gdb
      lldb
      strace
      ltrace

      # IDE and editor
      (lib.mkIf (config.profiles.dev.ide == "vscode") vscode)
      (lib.mkIf (config.profiles.dev.ide == "vscodium") vscodium)
      (lib.mkIf (config.profiles.dev.ide == "neovim") neovim)

      # Language servers and formatters
      nil # Nix LSP
      nixpkgs-fmt
      alejandra
      statix # Nix static analysis
    ];

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