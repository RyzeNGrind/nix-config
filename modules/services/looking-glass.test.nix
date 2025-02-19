{
  pkgs,
  lib,
  ...
}: {
  name = "looking-glass";

  nodes = {
    machine = {
      config,
      pkgs,
      ...
    }: {
      imports = [./looking-glass.nix];

      virtualisation = {
        memorySize = 2048;
        cores = 2;
        libvirtd.enable = true;
      };

      services = {
        looking-glass = {
          enable = true;
          memSize = "128M";
          autoStart = true;
          extraArgs = ["-f" "input:grabKeyboard=yes"];
        };

        xserver = {
          enable = true;
          displayManager.lightdm.enable = true;
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    with subtest("Basic configuration"):
        machine.succeed("test -e /dev/shm/looking-glass")
        machine.succeed("stat -c %a /dev/shm/looking-glass | grep -q 660")

    with subtest("Service configuration"):
        machine.succeed("systemctl is-enabled looking-glass.service")
        machine.succeed("systemctl is-active looking-glass.service")

    with subtest("IOMMU and VFIO setup"):
        machine.succeed("lsmod | grep -q vfio")
        machine.succeed("lsmod | grep -q vfio_pci")
        machine.succeed("dmesg | grep -i -e DMAR -e IOMMU")

    with subtest("Looking Glass client"):
        machine.succeed("which looking-glass-client")
        machine.succeed("getcap $(which looking-glass-client) | grep -q cap_sys_nice")

    with subtest("Virtualization setup"):
        machine.succeed("systemctl is-active libvirtd.service")
        machine.succeed("virsh list")
  '';
}
