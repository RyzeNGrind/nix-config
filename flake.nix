{
  description = "A comprehensive NixOS configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    std = {
      url = "github:divnix/std";
      inputs = {
        devshell.url = "github:numtide/devshell";
        nixago.url = "github:nix-community/nixago";
        nixpkgs.follows = "nixpkgs"; # Corrected follows usage
      };
    };
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    hardware.url = "github:nixos/nixos-hardware";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
  };

  outputs = { self, nixpkgs, std, home-manager, flake-utils, ... } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ ];
      };

      vm-test-config = import ./nix/hosts/vm-test.nix { inherit pkgs lib; };

      runVmScript = pkgs.writeShellScript "run-vm.sh" ''
        export NIX_DISK_IMAGE=$(mktemp -u -t nixos.qcow2)
        trap "rm -f $NIX_DISK_IMAGE" EXIT
        ${vm-test-config.config.system.build.vm}/bin/run-nixos-vm
      '';
    in
    {
      nixosConfigurations = std.growOn {
        inherit inputs;
        cellsFrom = ./nix;
        cellBlocks = with std.blockTypes; [
          #(nixosConfiguration "vm-test" (import ./nix/hosts/vm-test.nix { inherit pkgs lib; }))
          (nixosConfiguration "vm-test-config")
          (nixosConfiguration "base-system" (import ./nix/hosts/base-system.nix { inherit system; }))
          (homeManagerConfiguration "ryzengrind" ./nix/users/ryzengrind.nix)
          (nixago "configs" ./nix/repo/configs.nix)
          (devshells "shells" ./nix/repo/shells.nix)
        ];
      };

      apps.x86_64-linux.vm = {
        type = "app";
        program = runVmScript;
      };
    };
}
