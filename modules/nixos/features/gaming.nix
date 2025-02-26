# Gaming features module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.core.features;
in {
  options.core.features = with lib; {
    gaming = {
      enable = mkEnableOption "Gaming support";
      steam.enable = mkEnableOption "Steam support";
      wine.enable = mkEnableOption "Wine support";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.gaming.enable {
      hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };
      hardware.pulseaudio.support32Bit = true;
    })

    (lib.mkIf cfg.gaming.steam.enable {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
      environment.systemPackages = with pkgs; [
        steam-run
        gamescope
        mangohud
      ];
    })

    (lib.mkIf cfg.gaming.wine.enable {
      environment.systemPackages = with pkgs; [
        wine
        winetricks
        protontricks
        lutris
        bottles
      ];
    })
  ];
}
