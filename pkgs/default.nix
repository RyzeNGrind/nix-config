# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{ system, pkgs ? (import ../nixpkgs.nix) { inherit system; } }:

let
  # Define supported systems for TensorRT
  isSupportedSystem = system: builtins.elem system [
    "x86_64-linux"
    "aarch64-linux"
  ];

  # Create a dummy derivation that just creates an empty directory
  emptyDrv = pkgs.stdenv.mkDerivation {
    name = "empty-drv";
    version = "0.0.1";
    phases = [ "installPhase" ];
    installPhase = "mkdir -p $out";
  };

  # Create the tensorrt package if system is supported
  tensorrtPkg = if isSupportedSystem system 
    then pkgs.callPackage ./tensorrt { inherit (pkgs) cudaPackages; }
    else emptyDrv;
in
{
  # Expose both as separate attributes
  tensorrt = tensorrtPkg;
  default = tensorrtPkg;
}
