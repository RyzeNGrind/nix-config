# Base configuration for all specialisations
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Import core modules
  imports = [
    ../../modules/core/features.nix
    ../../modules/core/network.nix
  ];

  # System configuration
  system = {
    stateVersion = "24.05";
    autoUpgrade = {
      enable = true;
      allowReboot = false;
      channel = "https://channels.nixos.org/nixos-24.05";
    };
  };

  # Base system settings
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes" "auto-allocate-uids"];
      auto-optimise-store = true;
      trusted-users = ["root" "ryzengrind" "@wheel"];
      max-jobs = "auto";
      cores = 0;
      keep-outputs = true;
      keep-derivations = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  # Base networking
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Base system packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    coreutils
    curl
    git
    vim
    wget

    # System monitoring
    htop
    iotop
    lsof

    # Development tools
    gnumake
    gcc
    python3

    # Security tools
    gnupg
    openssl
  ];

  # Base security configuration
  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
    apparmor.enable = true;
  };

  # Base user configuration
  users.users.ryzengrind = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.";
  };

  # Base service configuration
  services = {
    # SSH for remote access
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    # Time synchronization
    timesyncd.enable = true;
  };

  # Base locale and time configuration
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Base boot configuration
  boot = {
    tmp.cleanOnBoot = true;
    kernel.sysctl = {
      "kernel.panic" = 10;
      "kernel.panic_on_oops" = 1;
      "vm.swappiness" = 10;
    };
  };

  # Base system optimization
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # Testing configuration
  testing = {
    enable = true;
    testScript = ''
      # Test base configuration
      machine.wait_for_unit("multi-user.target")
      machine.succeed("test -f /etc/nixos/configuration.nix")

      # Test core features
      with subtest("Core features"):
          machine.succeed("systemctl is-active sshd")
          machine.succeed("systemctl is-active timesyncd")
          machine.succeed("test -d /nix/store")

      # Test user setup
      with subtest("User configuration"):
          machine.succeed("id ryzengrind")
          machine.succeed("groups ryzengrind | grep -q wheel")

      # Test network
      with subtest("Network configuration"):
          machine.succeed("systemctl is-active NetworkManager")
          machine.succeed("ping -c 1 8.8.8.8")

      # Test security
      with subtest("Security configuration"):
          machine.succeed("systemctl is-active apparmor")
          machine.succeed("test -f /etc/sudoers")
    '';
  };
}
