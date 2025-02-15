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

    flakeInputs = mkOption {
      type = types.attrs;
      default = {};
      description = "Flake inputs to expose in /etc";
    };

    tags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "System tags for version labeling";
    };
  };

  config = lib.mkIf cfg.enable {
    # Store flake inputs in /etc
    environment.etc = {
      self.source = cfg.flakeInputs.self;
      nixpkgs.source = cfg.flakeInputs.nixpkgs;
    };

    system = {
      extraSystemBuilderCmds = "ln -s ${cfg.flakeInputs.self.sourceInfo.outPath} $out/src";
      nixos = {
        enable = true;
        inherit (cfg) flakeInputs tags;
        label = lib.concatStringsSep "-" (
          (lib.sort (x: y: x < y) cfg.tags)
          ++ ["${config.system.nixos.version}.${cfg.flakeInputs.self.sourceInfo.shortRev or "dirty"}"]
        );
      };
      inherit (cfg) stateVersion;
    };
  };
}
