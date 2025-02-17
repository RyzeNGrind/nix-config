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

    # daimyo with specializations
    daimyo = {
      imports = [
        ../hosts/daimyo/wsl.nix
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

    # Test daimyo default configuration
    with subtest("daimyo default configuration"):
        daimyo.wait_for_unit("multi-user.target")
        daimyo.succeed("test \"$(hostname)\" = \"daimyo\"")
        daimyo.succeed("docker --version")
        daimyo.succeed("test -n \"$DISPLAY\"")

    # Test CUDA specialization
    with subtest("CUDA specialization"):
        daimyo.succeed("nixos-rebuild test --specialisation cuda")
        daimyo.succeed("test -n \"$NVIDIA_DRIVER_CAPABILITIES\"")
        daimyo.succeed("test -n \"$NVIDIA_VISIBLE_DEVICES\"")
        daimyo.succeed("test -n \"$NVIDIA_REQUIRE_CUDA\"")

    # Test no-GUI specialization
    with subtest("No-GUI specialization"):
        daimyo.succeed("nixos-rebuild test --specialisation nogui")
        daimyo.fail("test -n \"$DISPLAY\"")
        daimyo.fail("test -n \"$WAYLAND_DISPLAY\"")
        daimyo.fail("test -n \"$XDG_RUNTIME_DIR\"")

    # Test minimal specialization
    with subtest("Minimal specialization"):
        daimyo.succeed("nixos-rebuild test --specialisation minimal")
        daimyo.fail("test -n \"$DISPLAY\"")
        daimyo.fail("which docker")
        daimyo.succeed("which curl")
        daimyo.succeed("which git")

    # Test switching back to default
    with subtest("Switch back to default"):
        daimyo.succeed("nixos-rebuild test")
        daimyo.succeed("test -n \"$DISPLAY\"")
        daimyo.succeed("which docker")
        daimyo.succeed("which vscode")

    # Test backup functionality
    with subtest("Backup functionality"):
        daimyo.succeed("test -e /etc/nixos.bak")
        daimyo.succeed("test -e /etc/systemd.bak")

    # Test system services
    with subtest("System services"):
        daimyo.wait_for_unit("docker.service")
        daimyo.wait_for_unit("vscode-server.service")
        daimyo.succeed("systemctl is-active auto-upgrade.timer")

    # Test development tools
    with subtest("Development tools"):
        daimyo.succeed("git --version")
        daimyo.succeed("python3 --version")
        daimyo.succeed("node --version")
        daimyo.succeed("rustup --version")

    # Test system monitoring
    with subtest("System monitoring"):
        daimyo.succeed("btop --version")
        daimyo.succeed("iotop --version")
        daimyo.succeed("ncdu --version")
  '';
}
