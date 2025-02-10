{
  config,
  lib,
  pkgs,
  ...
}: {
  name = "wsl-module-test";
  nodes.machine = {...}: {
    imports = [./wsl.nix];

    # Enable WSL with all features for testing
    services.wsl = {
      enable = true;

      gui = {
        enable = true;
        defaultDisplay = ":0";
      };

      cuda = {
        enable = true;
        version = "12.0";
      };

      automount = {
        enable = true;
        options = "metadata,uid=1000,gid=100";
      };

      network = {
        generateHosts = true;
        generateResolvConf = true;
      };
    };

    # Required for testing
    virtualisation.memorySize = 2048;
    virtualisation.cores = 2;
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Test WSL configuration
    with subtest("Basic WSL configuration"):
        machine.succeed("test -e /etc/wsl.conf")
        machine.succeed("grep 'enabled=true' /etc/wsl.conf")

    # Test GUI setup
    with subtest("GUI configuration"):
        machine.succeed("test -e /run/user/1000")
        machine.succeed("test -n \"$DISPLAY\"")
        machine.succeed("which xhost")

    # Test CUDA environment
    with subtest("CUDA configuration"):
        machine.succeed("test -n \"$NVIDIA_DRIVER_CAPABILITIES\"")
        machine.succeed("test -n \"$NVIDIA_VISIBLE_DEVICES\"")
        machine.succeed("test -n \"$NVIDIA_REQUIRE_CUDA\"")

    # Test automount
    with subtest("Automount configuration"):
        machine.succeed("test -d /mnt")
        machine.succeed("mount | grep -q '^.*on /mnt'")

    # Test network configuration
    with subtest("Network configuration"):
        machine.succeed("test -f /etc/hosts")
        machine.succeed("test -f /etc/resolv.conf")
        machine.succeed("grep -q 'localhost' /etc/hosts")
  '';
}
