# Desktop environment profile
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.desktop;
in {
  imports = [
    # Import required upstream modules
    ../cursor
  ];

  options.profiles.desktop = with lib; {
    enable = mkEnableOption "desktop environment profile";

    apps = {
      browsers.enable = mkEnableOption "web browsers";
      communication.enable = mkEnableOption "communication tools";
      media.enable = mkEnableOption "media applications";
      remote = {
        enable = mkEnableOption "remote access tools";
        termius.enable = mkEnableOption "cloud ssh client";
        synergy.enable = mkEnableOption "synergy tools";
        remote-desktop.enable = mkEnableOption "remote-desktop tools";
      };
    };

    wm = {
      enable = mkEnableOption "window manager";
      hyprland.enable = mkEnableOption "Hyprland window manager";
    };
  };

  config = lib.mkIf cfg.enable {
    # Desktop environment packages
    environment.systemPackages = with pkgs;
      lib.mkMerge [
        (lib.mkIf cfg.apps.browsers.enable [
          firefox
          ungoogled-chromium
        ])
        (lib.mkIf cfg.apps.communication.enable [
          discord
        ])
        (lib.mkIf cfg.apps.remote.enable (lib.mkMerge [
          (lib.mkIf cfg.apps.remote.termius.enable [termius])
          (lib.mkIf cfg.apps.remote.synergy.enable [synergy])
          (lib.mkIf cfg.apps.remote.remote-desktop.enable [teamviewer rustdesk])
        ]))
        (lib.mkIf cfg.apps.media.enable [
          vlc
        ])
        (lib.mkIf cfg.wm.hyprland.enable [
          hyprland
        ])
      ];

    # Enable desktop services
    services = {
      xserver.enable = true;
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    };

    # Desktop-specific programs
    programs = {
      firefox.enable = true;
      chromium = {
        enable = true;
        extraOpts = {
          "BrowserSignin" = 0;
          "SyncDisabled" = true;
        };
      };
    };
  };
}
