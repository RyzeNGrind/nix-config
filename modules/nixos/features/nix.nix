# Nix-specific features module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.core.features;
in {
  options.core.features = with lib; {
    nix-ld.enable = mkEnableOption "nix-ld support for running unpatched dynamic binaries";
    nix-index.enable = mkEnableOption "nix-index for searching available packages";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.nix-ld.enable {
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc
          openssl
          curl
          glib
          util-linux
          glibc
          icu
          libunwind
          libuuid
          zlib
        ];
      };
    })

    (lib.mkIf cfg.nix-index.enable {
      environment.systemPackages = [pkgs.nix-index];
      programs.command-not-found.enable = false;
    })
  ];
}
