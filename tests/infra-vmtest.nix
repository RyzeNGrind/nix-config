{
  pkgs,
  nixosModules,
  ...
}: let
  # Test environment variables
  test-env = pkgs.writeText "test-env" ''
    FISSION_NAMESPACE=fission-test
    ATTIC_ENDPOINT=http://localhost:8080
  '';

in pkgs.nixosTest {
  name = "infra-tools-test";
  
  nodes = {
    machine = { config, pkgs, ... }: {
      virtualisation = {
        cores = 4;
        memorySize = 4096;
        docker.enable = true;
      };

      imports = [
        nixosModules.default
        ../modules/nixos/infra-tools.nix
      ];

      # Enable and configure infrastructure tools
      services.cluster-tools = {
        enable = true;
        cloud-tools = {
          enableKubevela = true;
          enableFission = true;
          enableAttic = true;
          enableRay = true;
          
          fission.namespace = "fission-test";
          atticCache.endpoint = "http://localhost:8080";
        };
        
        infra-tools = {
          nodeRole = "devops";
          deploymentEnvironment = "dev";
        };
      };

      # System configuration for testing
      environment.systemPackages = with pkgs; [
        kubectl
        k9s
        docker-compose
        curl
        jq
      ];

      networking.firewall.enable = false;
      services.k3s.enable = true;
      services.k3s.role = "server";
    };
  };

  testScript = ''
    start_all()

    # Wait for essential services
    machine.wait_for_unit("docker.service")
    machine.wait_for_unit("k3s.service")
    
    with subtest("Check if Docker is working"):
        machine.succeed("docker ps")
        machine.succeed("docker run hello-world")
    
    with subtest("Check if Kubernetes (k3s) is working"):
        machine.wait_until_succeeds("kubectl get nodes")
        machine.succeed("kubectl get nodes | grep 'Ready'")
    
    with subtest("Check if KubeVela is properly installed"):
        machine.wait_until_succeeds("vela version")
        machine.succeed("vela env init testing --namespace testing")
    
    with subtest("Check if Fission is properly installed"):
        machine.wait_until_succeeds("fission version")
        machine.succeed(
            "fission env create --name nodejs --image fission/node-env"
        )
    
    with subtest("Check if Attic is properly installed"):
        machine.wait_until_succeeds("attic --version")
    
    with subtest("Check if Ray is properly installed"):
        machine.succeed("python3 -c 'import ray; ray.init()'")
    
    with subtest("Verify node configuration"):
        result = machine.succeed("nixos-option services.cluster-tools.infra-tools.nodeRole")
        assert "devops" in result, f"Expected nodeRole to be devops, got {result}"
        
        result = machine.succeed("nixos-option services.cluster-tools.infra-tools.deploymentEnvironment")
        assert "dev" in result, f"Expected deploymentEnvironment to be dev, got {result}"
    
    with subtest("Test infrastructure deployment"):
        # Deploy a test application using KubeVela
        machine.succeed('''
            cat > test-app.yaml <<EOF
            apiVersion: core.oam.dev/v1beta1
            kind: Application
            metadata:
              name: test-app
              namespace: testing
            spec:
              components:
                - name: test-server
                  type: webservice
                  properties:
                    image: nginx
                    ports:
                      - port: 80
            EOF
        ''')
        machine.succeed("vela up -f test-app.yaml")
        machine.wait_until_succeeds("kubectl get pod -n testing -l app.oam.dev/name=test-app | grep Running")
    
    machine.shutdown()
  '';
} 