# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: prev: import ./additions.nix final prev;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: import ./modifications.nix final prev;

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  tensorrt = import ./tensorrt.nix;
  unstable = _final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (prev) system;
      config.allowUnfree = true;
    };
  };
}
