{
  config,
  lib,
  pkgs,
  ...
}: {
  name = "base-profile-test";

  nodes.machine = {...}: {
    imports = [./default.nix];

    # Enable base profile with all features
    profiles.base = {
      enable = true;
      security = {
        enable = true;
        hardening = true;
      };
    };

    # Required for testing
    virtualisation = {
      memorySize = 2048;
      cores = 2;
      # Enable nested virtualization for AppArmor testing
      nested.enable = true;
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Test core system settings
    with subtest("Core system settings"):
        # Check Nix configuration
        machine.succeed("test -d /nix/store")
        machine.succeed("nix-env --version")
        machine.succeed("test -n \"$NIX_PATH\"")

        # Check system optimization
        machine.succeed("test -e /dev/zram0")
        machine.succeed("swapon -s | grep -q zram0")

    # Test security features
    with subtest("Security features"):
        # Check AppArmor
        machine.succeed("systemctl is-active apparmor.service")
        machine.succeed("aa-status")

        # Check audit daemon
        machine.succeed("systemctl is-active auditd.service")
        machine.succeed("test -f /var/log/audit/audit.log")

        # Check PAM configuration
        machine.succeed("test -f /etc/security/limits.conf")
        machine.succeed("grep -q '@wheel.*nofile' /etc/security/limits.conf")

    # Test system packages
    with subtest("System packages"):
        for pkg in ["curl", "git", "vim", "wget", "htop", "gnupg"]:
            machine.succeed(f"which {pkg}")

    # Test kernel parameters
    with subtest("Kernel parameters"):
        machine.succeed("sysctl -n vm.swappiness | grep -q '^10$'")
        machine.succeed("sysctl -n kernel.panic | grep -q '^10$'")

    # Test system hardening
    with subtest("System hardening"):
        # Check kernel module loading restrictions
        machine.succeed("test -f /proc/sys/kernel/modules_disabled")

        # Check kernel image protection
        machine.succeed("test -f /proc/sys/kernel/kexec_load_disabled")

        # Check page table isolation
        machine.succeed("grep -q 'pti' /proc/cmdline")

    # Test system features
    with subtest("System features"):
        # Check nix-ld
        machine.succeed("test -n \"$NIX_LD\"")
        machine.succeed("test -n \"$NIX_LD_LIBRARY_PATH\"")

        # Check nix-index
        machine.succeed("which nix-index")
        machine.succeed("test -d /root/.cache/nix-index")

    # Test system logs
    with subtest("System logs"):
        machine.succeed("journalctl --no-pager -n 100")
        machine.succeed("test -d /var/log")
  '';
}
