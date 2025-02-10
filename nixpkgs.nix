# This file controls the pinned version of nixpkgs
args: args

# Import the flake's nixpkgs
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nixpkgs = fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/${lock.nodes.nixpkgs.locked.rev}.tar.gz";
    sha256 = lock.nodes.nixpkgs.locked.narHash;
  };
in
import nixpkgs (
  args
  // {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  }
)
