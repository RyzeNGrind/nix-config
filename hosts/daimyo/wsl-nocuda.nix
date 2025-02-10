# WSL configuration without CUDA support
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Import WSL base configuration
  imports = [
    ../base/wsl.nix
  ];

  # Explicitly disable CUDA support
  nixpkgs.config = {
    cudaSupport = false;
    cudaCapabilities = [];
  };

  # Disable all NVIDIA/CUDA related features
  hardware = {
    nvidia = {
      package = null;
      modesetting.enable = false;
    };
    nvidia-container-toolkit.enable = false;
    opengl.enable = lib.mkForce false;
  };

  # Disable NVIDIA container runtime in Docker
  virtualisation.docker = {
    enableNvidia = false;
    extraOptions = "--add-runtime none=runc";
  };

  # Environment variables to prevent CUDA detection
  environment.variables = {
    CUDA_PATH = "";
    LD_LIBRARY_PATH = "";
    NVIDIA_DRIVER_CAPABILITIES = "";
    NVIDIA_VISIBLE_DEVICES = "none";
  };

  # Testing configuration
  testing = {
    enable = true;
    testScript = ''
      # Test CUDA is disabled
      with subtest("CUDA disabled"):
          machine.fail("which nvidia-smi")
          machine.fail("which nvcc")
          machine.succeed("test -z \"$CUDA_PATH\"")
          machine.succeed("test -z \"$NVIDIA_VISIBLE_DEVICES\"")

      # Test Docker without NVIDIA
      with subtest("Docker without NVIDIA"):
          machine.succeed("docker info | grep -v 'nvidia'")
          machine.fail("docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi")
    '';
  };
}
