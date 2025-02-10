_: {
  name = "specialisation-test";

  nodes = {
    # Base WSL configuration
    wsl = {
      imports = [
        ../hosts/base/wsl.nix
      ];
      virtualisation.memorySize = 2048;
    };

    # daimyo00 with specializations
    daimyo00 = {
      imports = [
        ../hosts/daimyo00/wsl.nix
      ];
      virtualisation.memorySize = 2048;
    };
  };

  testScript = ''
    start_all()

    # Test base WSL configuration
    with subtest("Base WSL configuration"):
        wsl.wait_for_unit("multi-user.target")
        wsl.succeed("test -e /etc/wsl.conf")
        wsl.succeed("test -n \"$DISPLAY\"")
        wsl.succeed("which wslu")
        wsl.succeed("which wsl-open")

    # Test daimyo00 default configuration
    with subtest("daimyo00 default configuration"):
        daimyo00.wait_for_unit("multi-user.target")
        daimyo00.succeed("test \"$(hostname)\" = \"daimyo00\"")
        daimyo00.succeed("docker --version")
        daimyo00.succeed("test -n \"$DISPLAY\"")

    # Test CUDA specialization
    with subtest("CUDA specialization"):
        daimyo00.succeed("nixos-rebuild test --specialisation cuda")
        daimyo00.succeed("test -n \"$NVIDIA_DRIVER_CAPABILITIES\"")
        daimyo00.succeed("test -n \"$NVIDIA_VISIBLE_DEVICES\"")
        daimyo00.succeed("test -n \"$NVIDIA_REQUIRE_CUDA\"")

    # Test no-GUI specialization
    with subtest("No-GUI specialization"):
        daimyo00.succeed("nixos-rebuild test --specialisation nogui")
        daimyo00.fail("test -n \"$DISPLAY\"")
        daimyo00.fail("test -n \"$WAYLAND_DISPLAY\"")
        daimyo00.fail("test -n \"$XDG_RUNTIME_DIR\"")

    # Test minimal specialization
    with subtest("Minimal specialization"):
        daimyo00.succeed("nixos-rebuild test --specialisation minimal")
        daimyo00.fail("test -n \"$DISPLAY\"")
        daimyo00.fail("which docker")
        daimyo00.succeed("which curl")
        daimyo00.succeed("which git")

    # Test switching back to default
    with subtest("Switch back to default"):
        daimyo00.succeed("nixos-rebuild test")
        daimyo00.succeed("test -n \"$DISPLAY\"")
        daimyo00.succeed("which docker")
        daimyo00.succeed("which vscode")

    # Test backup functionality
    with subtest("Backup functionality"):
        daimyo00.succeed("test -e /etc/nixos.bak")
        daimyo00.succeed("test -e /etc/systemd.bak")

    # Test system services
    with subtest("System services"):
        daimyo00.wait_for_unit("docker.service")
        daimyo00.wait_for_unit("vscode-server.service")
        daimyo00.succeed("systemctl is-active auto-upgrade.timer")

    # Test development tools
    with subtest("Development tools"):
        daimyo00.succeed("git --version")
        daimyo00.succeed("python3 --version")
        daimyo00.succeed("node --version")
        daimyo00.succeed("rustup --version")

    # Test system monitoring
    with subtest("System monitoring"):
        daimyo00.succeed("btop --version")
        daimyo00.succeed("iotop --version")
        daimyo00.succeed("ncdu --version")
  '';
}
