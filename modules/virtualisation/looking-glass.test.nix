{
  pkgs,
  lib,
  ...
}: {
  name = "looking-glass-test";

  nodes.machine = {
    config,
    pkgs,
    ...
  }: {
    imports = [./looking-glass.nix];
    virtualisation.memorySize = 2048;
    virtualisation.cores = 2;

    services.looking-glass = {
      enable = true;
      autoStart = true;
      memSize = "256M";
      user = "testuser";
      extraArgs = ["-f" "input:grabKeyboard=yes"];
    };

    # Create test user
    users.users.testuser = {
      isNormalUser = true;
      uid = 1000;
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    with subtest("Basic configuration"):
        machine.succeed("test -e /dev/shm/looking-glass")
        machine.succeed("ls -l /dev/shm/looking-glass | grep -q 'testuser.*kvm'")
        machine.succeed("ls -l /dev/shm/looking-glass | grep -q '256M'")

    with subtest("Service configuration"):
        machine.succeed("systemctl is-enabled looking-glass")
        machine.succeed("systemctl is-active looking-glass")

    with subtest("User configuration"):
        machine.succeed("groups testuser | grep -q kvm")

    with subtest("Kernel configuration"):
        machine.succeed("lsmod | grep -q vfio")
        machine.succeed("lsmod | grep -q vfio_pci")
        machine.succeed("grep -q 'intel_iommu=on\|amd_iommu=on' /proc/cmdline")

    with subtest("Virtualization setup"):
        machine.succeed("systemctl is-enabled libvirtd")
        machine.succeed("systemctl is-active libvirtd")
        machine.succeed("test -e /run/libvirt/libvirt-sock")

    with subtest("Security configuration"):
        machine.succeed("test -e /run/wrappers/bin/looking-glass-client")
        machine.succeed("getcap /run/wrappers/bin/looking-glass-client | grep -q cap_sys_nice")
  '';
}
