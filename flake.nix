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
      inputs.devshell.url = "github:numtide/devshell";
      inputs.nixago.url = "github:nix-community/nixago";
      inputs.nixpkgs.follows = "nixpkgs"; #This makes `std`'s `nixpkgs` follow the top-level `nixpkgs`
    };
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    hardware.url = "github:nixos/nixos-hardware";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
  };

  outputs = { self, nixpkgs, std, home-manager, flake-utils, ... } @ inputs:
    let
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [ ];
      };
      
      # Assuming vm-test.nix returns a NixOS configuration
      vmConfig = std.growOn {
        inherit inputs;
        cellsFrom = ./nix;
        cellBlocks = with std.blockTypes; [
          (nixosConfiguration "vm-test" ./nix/hosts/vm-test.nix)
          # Add other configurations as needed
        ];
      }.nixosConfigurations.vm-test;
      
      # Create the VM startup script
      runVmScript = pkgs.writeShellScript "run-vm.sh" ''
        export NIX_DISK_IMAGE=$(mktemp -u -t nixos.qcow2)
        trap "rm -f $NIX_DISK_IMAGE" EXIT
        ${vmConfig.config.system.build.vm}/bin/run-nixos-vm
      '';
    in
    {
      apps.x86_64-linux.vm = {
        type = "app";
        program = runVmScript;
      };

      defaultApp.x86_64-linux = self.apps.x86_64-linux.vm;

      devShells = {
        x86_64-linux = {
          vm-test = pkgs.mkShell {
            buildInputs = [ pkgs.hello ]; # Define your development environment here
          };
        };
      };

      nixosConfigurations = std.growOn {
        inherit inputs;
        cellsFrom = ./nix;

        cellBlocks = with std.blockTypes; [
          (nixosConfiguration "vm-test" ./nix/hosts/vm-test.nix)
          (nixosConfiguration "base-system" ./nix/hosts/base-system.nix)
          (homeManagerConfiguration "ryzengrind" ./nix/users/ryzengrind.nix)
          (nixago "configs" ./nix/repo/configs.nix)
          (devshells "shells" ./nix/repo/shells.nix)
        ];
      };
    };
}
