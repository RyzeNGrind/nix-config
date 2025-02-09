# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{ system, pkgs ? (import ../nixpkgs.nix) { inherit system; } }: {
  # example = pkgs.callPackage ./example { };
  tensorrt = pkgs.callPackage ./tensorrt {
    inherit (pkgs) cudaPackages;
  };
}
