# Core system test module
{
  config,
  pkgs,
  lib,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/testing/test-instrumentation.nix"
    "${modulesPath}/virtualisation/qemu-vm.nix"
    ../../modules/core/system.nix
    ../../modules/core/spec.nix
    inputs.nixos-wsl.nixosModules.wsl
  ];

  # Enable and configure core
  core = {
    system = {
      enable = true;
      flakeInputs = inputs;
      stateVersion = "24.05";
    };
    spec = {
      enable = true;
      wsl = {
        enable = false;
        cuda = false;
        gui = false;
      };
      development = {
        enable = false;
        containers = false;
        languages = [];
      };
    };
  };

  virtualisation = {
    memorySize = 2048;
    cores = 2;
    graphics = false;
    useBootLoader = false;
    useEFIBoot = false;
    writableStore = true;
    qemu = {
      options = ["-nographic"];
    };
  };

  environment.systemPackages = with pkgs; [
    coreutils
    procps
    iproute2
    python3
    htop
  ];
}
