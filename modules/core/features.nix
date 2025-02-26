# Core feature flag system
{
  config,
  lib,
  ...
}: let
  cfg = config.core.features;
in {
  imports = [
    ../nixos/features
  ];

  options.core.features = with lib; {
    enable = mkEnableOption "feature flag system";

    # Feature flags
    flags = mkOption {
      type = types.attrsOf types.bool;
      default = {};
      description = "Feature flags state";
    };

    categories = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {
        configuration_style = ["verbose" "minimal" "debug" "concise"];
        system_management = ["performance" "security" "docs" "maintenance"];
        learning_mode = ["explain" "references"];
        special_modes = ["migration" "home-manager" "darwin" "nixos"];
      };
      description = "Available feature flag categories";
    };

    default_enabled = mkOption {
      type = types.listOf types.str;
      default = [
        "reproducible"
        "pure"
        "modular"
        "alternatives"
        "cross-platform"
      ];
      description = "Default enabled feature flags";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Initialize default feature flags
    {
      core.features.flags = lib.mkMerge [
        (lib.genAttrs cfg.default_enabled (_name: true))
        {
          # Add any additional flag states here
        }
      ];
    }

    # Feature flag dependent configurations
    {
      nix.settings = lib.mkMerge [
        (lib.mkIf cfg.flags.reproducible {
          keep-outputs = true;
          keep-derivations = true;
        })
        (lib.mkIf cfg.flags.pure {
          sandbox = true;
          restrict-eval = true;
        })
      ];

      documentation = lib.mkIf cfg.flags.docs {
        enable = true;
        dev.enable = true;
        doc.enable = true;
        info.enable = true;
        man.enable = true;
      };

      boot.tmp.cleanOnBoot = lib.mkIf cfg.flags.performance true;
      nix.gc = lib.mkIf cfg.flags.maintenance {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    }

    # Feature version tracking
    {
      system.nixos.version = lib.mkIf (cfg != {}) (
        let
          enabledFeatures = lib.concatStringsSep "," (
            lib.mapAttrsToList (name: value:
              if value.enable or value
              then "${name}"
              else null)
            (lib.filterAttrs (name: _: name != "_module") cfg)
          );
        in "${config.system.nixos.version}+features.${enabledFeatures}"
      );
    }
  ]);
}
