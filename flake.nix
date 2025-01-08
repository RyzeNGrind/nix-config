{
  description = "NixOS Hyperconverged Infrastructure Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Add nixos-generators
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Infrastructure tools
    infra-ml = {
      infra-mlops = {
        edge = {
          colossalai.url = "github:hpcaitech/ColossalAI";
        };
        bleeding-edge = {
          # Add more MLOps-related bleeding-edge tools here
        };
      };
    };

    infra-dev = {
      infra-devops = {
        edge = {
          flox.url = "github:flox/flox";
          kubevela.url = "github:kubevela/kubevela";
          attic.url = "github:zhaofengli/attic";
          fission.url = "github:fission/fission";
        };
        bleeding-edge = {
          # Add more DevOps-related bleeding-edge tools here
        };
      };
    };

    # System
    hardware.url = "github:nixos/nixos-hardware";
    nixos-wsl.url = "github:nix-community/nixos-wsl";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, nixos-generators, ... }@inputs:
    let
      inherit (self) outputs;
      # Supported systems for your flake packages, shell, etc.
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      # This is a function that generates an attribute by calling a function you
      # pass to it, with each system as an argument
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Helper function to create system configurations
      mkSystem = hostname: system: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./modules/nixos/formats.nix
          nixos-generators.nixosModules.all-formats
          {
            networking.hostName = hostname;
            nixpkgs.hostPlatform = system;
          }
        ] ++ extraModules;
      };

    in {
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      packages =
        forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      # Formatter for your nix files, available through 'nix fmt'
      # Other options beside 'alejandra' include 'nixpkgs-fmt'
      formatter =
        forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint~
      # Available through 'sudo nixos-rebuild switch --flake 'github:RyzeNGrind/nix-config#daimyo00''
      nixosConfigurations = {
        # WSL configuration
        daimyo00 = mkSystem "daimyo00" "x86_64-linux" [
          inputs.nixos-wsl.nixosModules.default
          ./modules/nixos-wsl/override-build-tarball.nix
          ./hosts/daimyo00/configuration.nix
        ];

        # Example VM configuration
        vm-test = mkSystem "vm-test" "x86_64-linux" [
          {
            formatConfigs.vmware = {
              services.openssh.enable = true;
              users.users.root.password = "nixos";
            };
          }
        ];

        # Example container configuration
        container-test = mkSystem "container-test" "x86_64-linux" [
          {
            formatConfigs.docker = {
              services.openssh.enable = false;
              users.users.root.password = "";
            };
          }
        ];
      };

      # Add format-specific outputs
      packages = forAllSystems (system: 
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          # VM images
          vm-test-vmware = self.nixosConfigurations.vm-test.config.formats.vmware;
          vm-test-virtualbox = self.nixosConfigurations.vm-test.config.formats.virtualbox;
          vm-test-qcow2 = self.nixosConfigurations.vm-test.config.formats.qcow2;

          # Container images
          container-test-docker = self.nixosConfigurations.container-test.config.formats.docker;

          # Installation media
          vm-test-iso = self.nixosConfigurations.vm-test.config.formats.iso;
        } // (import ./pkgs pkgs)
      );

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#ryzengrind@daimyo00'
      homeConfigurations = {
        # FIXME replace with your username@hostname
        "ryzengrind@daimyo00" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./home-manager/home.nix
          ];
        };
      };

      # Add the VM tests
      checks = forAllSystems (system: {
        # Test infrastructure tools
        infra-vmtest = import ./tests/infra-vmtest.nix {
          inherit (nixpkgs.legacyPackages.${system}) pkgs;
          nixosModules = {
            default = self.nixosModules.default;
          };
        };

        # Test format configurations
        formats-vmtest = import ./tests/formats-vmtest.nix {
          inherit (nixpkgs.legacyPackages.${system}) pkgs;
          nixosModules = {
            default = self.nixosModules.default;
          };
        };
      });
    };
}
