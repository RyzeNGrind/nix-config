# Core system configuration
{
  config,
  pkgs,
  ...
}: {
  # Basic system configuration
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Common system packages
  environment.systemPackages = with pkgs; [
    # Development tools
    git
    git-lfs
    direnv
    nixfmt
    alejandra
    statix

    # System tools
    htop
    iotop
    neofetch
    curl
    jq
    wget
  ];

  # Nix settings
  nix = {
    settings = {
      experimental-features = "nix-command flakes auto-allocate-uids";
      auto-optimise-store = true;
      trusted-users = ["root" "@wheel"];
      max-jobs = "auto";
      cores = 0;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # User configuration
  users.users.ryzengrind = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker" "networkmanager"];
  };
}
