{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    # You can access packages and modules from different nixpkgs revs
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-cuda = {
      url = "github:nixos/nixpkgs/550.78"; # Known working CUDA driver version
      follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-WSL
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    
    # Hardware configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  nixConfig = {
    extra-substituters = [
      "https://cuda-maintainers.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    allow-broken = true;
    accept-flake-config = true;
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, ... } @ inputs: let
    inherit (self) outputs;
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Your custom packages
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays = import ./overlays { inherit inputs; };
    nixosModules = import ./modules/nixos;

    # Standalone home-manager configuration entrypoint
    homeConfigurations = {
      "ryzengrind@daimyo00" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs outputs; };
        modules = [
          ./hosts/daimyo00/home.nix
        ];
      };
    };

    # NixOS configuration entrypoint
    nixosConfigurations = {
      # WSL configuration
      daimyo00 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs outputs; };
        modules = [
          # Core modules
          ./hosts/daimyo00/configuration.nix
          
          # Allow broken packages
          {
            nixpkgs.config = {
              allowBroken = true;
              allowUnfree = true;
            };
          }
          
          # Home Manager module
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.ryzengrind = import ./hosts/daimyo00/home.nix;
              extraSpecialArgs = { inherit inputs outputs; };
            };
          }
        ];
      };
    };
  };
}
