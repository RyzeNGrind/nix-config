{
  config,
  lib,
  inputs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.core.system;
in {
  options.core.system = {
    enable = lib.mkEnableOption "Core system configuration";

    stateVersion = mkOption {
      type = types.str;
      default = "24.05";
      description = "NixOS state version";
    };

    tags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "System tags for version labeling";
    };
  };

  config = lib.mkIf cfg.enable {
    system = {
      inherit (cfg) stateVersion;
      nixos.tags = cfg.tags;
    };
  };
}
