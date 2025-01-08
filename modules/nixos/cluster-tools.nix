{config, lib, pkgs, ...}:

with lib;
let
  cfg = config.services.cluster-tools;
in {
  options.services.cluster-tools = {
    enable = mkEnableOption "Cluster tools suite";

    cloud-tools = {
      enableKubevela = mkEnableOption "Enable KubeVela for NoCode CD";
      enableFission = mkEnableOption "Enable Fission serverless platform";
      enableAttic = mkEnableOption "Enable Attic binary cache";
      enableRay = mkEnableOption "Enable Ray for AI compute";

      atticCache = {
        endpoint = mkOption {
          type = types.str;
          default = "https://cache.nixos.org";
          description = "Attic binary cache endpoint";
        };
      };

      fission = {
        namespace = mkOption {
          type = types.str;
          default = "fission";
          description = "Kubernetes namespace for Fission";
        };
      };
    };

    infra-tools = {
      nodeRole = mkOption {
        type = types.enum [ "devops" "mlops" "appops" ];
        default = "devops";
        description = "Role of the node for deployment";
      };

      deploymentEnvironment = mkOption {
        type = types.enum [ "dev" "staging" "prod" ];
        default = "dev";
        description = "Deployment environment for the node";
      };
    };
  };

  config = mkIf cfg.enable {
    # Base dependencies
    environment.systemPackages = with pkgs; [
      flox  # Development environment management
      kubernetes-helm  # Required for various deployments
      kubectl  # Kubernetes CLI
      k9s     # TUI for Kubernetes
    ] ++ optionals cfg.cloud-tools.enableKubevela [
      kubevela
    ] ++ optionals cfg.cloud-tools.enableFission [
      fission-cli
    ] ++ optionals cfg.cloud-tools.enableAttic [
      attic
    ] ++ optionals cfg.cloud-tools.enableRay [
      python3Packages.ray
    ];

    # Kubernetes and container runtime setup
    virtualisation.docker.enable = true;
    services.k3s.enable = true;
    services.k3s.role = "server";

    # Attic configuration if enabled
    nix.settings = mkIf cfg.cloud-tools.enableAttic {
      substituters = [ cfg.cloud-tools.atticCache.endpoint ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };

    # Fission configuration if enabled
    systemd.services = mkIf cfg.cloud-tools.enableFission {
      fission-controller = {
        description = "Fission Controller";
        wantedBy = [ "multi-user.target" ];
        after = [ "k3s.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.fission-cli}/bin/fission-controller --namespace=${cfg.cloud-tools.fission.namespace}";
          Restart = "always";
        };
      };
    };
  };
} 