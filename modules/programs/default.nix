{...}: {
  imports = [
    ./wayland/hyprlock.nix
    ./wayland/hyprland.nix
    ./iio-hyprland.nix
    ./chromium.nix
    ./firefox.nix
    ./fish.nix
    ./starship.nix
    ./ssh.nix
    ./git.nix
    ./_1password-gui.nix
    ./_1password.nix
  ];
}
