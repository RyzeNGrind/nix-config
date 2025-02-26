# Security and VPN profile
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.profiles.security;
in {
  options.profiles.security = with lib; {
    enable = mkEnableOption "security profile";

    vpn = {
      enable = mkEnableOption "VPN tools";
      proton.enable = mkEnableOption "ProtonVPN";
      tailscale.enable = mkEnableOption "Tailscale";
      zerotier.enable = mkEnableOption "ZeroTier";
    };

    tools = {
      enable = mkEnableOption "security tools";
      onepassword.enable = mkEnableOption "1Password";
      tor.enable = mkEnableOption "Tor Browser";
      v2ray.enable = mkEnableOption "V2Ray";
    };

    sudo = mkEnableOption "sudo";
    rtkit = mkEnableOption "rtkit";
  };

  config = lib.mkIf cfg.enable {
    # Basic security configuration
    security = {
      sudo.enable = cfg.sudo;
      rtkit.enable = cfg.rtkit;
    };

    # Security tools and packages
    environment.systemPackages = with pkgs;
      lib.mkMerge [
        # Base security tools
        [
          gnupg
          pass
          yubikey-personalization
          yubikey-manager
        ]
        # VPN tools
        (lib.mkIf cfg.vpn.enable (lib.mkMerge [
          (lib.mkIf cfg.vpn.proton.enable [protonvpn-gui])
          (lib.mkIf cfg.vpn.tailscale.enable [tailscale])
          (lib.mkIf cfg.vpn.zerotier.enable [zerotierone])
        ]))
        # Additional security tools
        (lib.mkIf cfg.tools.enable (lib.mkMerge [
          (lib.mkIf cfg.tools.onepassword.enable [
            _1password
            _1password-gui-beta
          ])
          (lib.mkIf cfg.tools.tor.enable [tor-browser-bundle-bin])
          (lib.mkIf cfg.tools.v2ray.enable [v2raya])
        ]))
      ];

    # Enable security services
    services = {
      inherit (cfg.vpn) tailscale;
      zerotierone.enable = cfg.vpn.zerotier.enable;
    };

    # Security-specific programs
    programs = {
      _1password = {
        inherit (cfg.tools.onepassword) enable;
        package = pkgs._1password;
      };
      _1password-gui = {
        inherit (cfg.tools.onepassword) enable;
        package = pkgs._1password-gui-beta;
      };
    };
  };
}
