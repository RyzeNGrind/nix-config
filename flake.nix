{
  description = "NixOS Hyperconverged Infrastructure Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Add nixos-generators
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Infrastructure tools
    colossalai = {
      url = "github:hpcaitech/ColossalAI";
      flake = false;
    };

    flox = {
      url = "github:flox/flox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kubevela = {
      url = "github:kubevela/kubevela";
      flake = false;
    };

    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fission = {
      url = "github:fission/fission";
      flake = false;
    };

    # System
    hardware.url = "github:nixos/nixos-hardware";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, nixos-generators, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      
      # Supported systems for your flake packages, shell, etc.
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      
      forAllSystems = lib.genAttrs systems;

      # Helper function to create system configurations
      mkSystem = hostname: system: extraModules: lib.nixosSystem {
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

      # Helper function for format-specific configurations
      mkFormatConfig = { name, system, modules ? [], formatConfig ? {} }: mkSystem name system ([
        nixos-generators.nixosModules.all-formats
        {
          system.stateVersion = "24.11";
          formats.${name} = formatConfig;
        }
      ] ++ modules);

      # Common format configurations
      baseFormatConfig = {
        docker = {
          services.openssh.enable = false;
          users.users.root.password = "";
          virtualisation.docker.enable = true;
        };

        install-iso = {
          isoImage.makeEfiBootable = true;
          isoImage.makeUsbBootable = true;
        };

        kexec = {
          boot.loader.grub.enable = false;
          boot.kernelParams = [ "console=ttyS0,115200" ];
        };

        sd-aarch64 = {
          hardware.raspberry-pi."4".enable = true;
        };
      };

    in {
      # Your custom packages and format outputs
      packages = forAllSystems (system: 
        let
          pkgs = nixpkgs.legacyPackages.${system};
          
          # Import custom packages
          customPkgs = import ./pkgs pkgs;

        in customPkgs // {
          # Docker image
          docker-test = self.nixosConfigurations.docker-test.config.formats.docker;
          
          # Installation ISO
          install-iso-test = self.nixosConfigurations.iso-test.config.formats.install-iso;
          
          # Kexec bundle
          kexec-test = self.nixosConfigurations.kexec-test.config.formats.kexec;
          kexec-bundle-test = self.nixosConfigurations.kexec-test.config.formats.kexec-bundle;
          
          # SD card image for aarch64
          sd-aarch64-test = self.nixosConfigurations.sd-test.config.formats.sd-aarch64-installer;

          # Meta package to build and test all formats
          all-formats = pkgs.runCommand "all-formats" {
            nativeBuildInputs = with pkgs; [ makeWrapper ];
          } ''
            mkdir -p $out/bin $out/formats
            
            # Create test script
            cat > $out/bin/test-all-formats <<'EOF'
            #!/usr/bin/env bash
            set -euo pipefail
            
            echo "Testing all formats..."
            
            # Test Docker
            echo "Testing Docker image..."
            nix build .#checks.${system}.format-tests.testDocker
            
            # Test ISO
            echo "Testing ISO image..."
            nix build .#checks.${system}.format-tests.testISO
            
            # Test Kexec
            echo "Testing Kexec bundle..."
            nix build .#checks.${system}.format-tests.testKexec
            
            if [ "${system}" = "aarch64-linux" ]; then
              echo "Testing SD card image..."
              nix build .#checks.${system}.format-tests.testSDImage
            fi
            
            echo "All tests passed!"
            EOF
            chmod +x $out/bin/test-all-formats
            
            # Create symlinks to all format outputs
            ln -s ${self.packages.${system}.docker-test} $out/formats/docker
            ln -s ${self.packages.${system}.install-iso-test} $out/formats/iso
            ln -s ${self.packages.${system}.kexec-test} $out/formats/kexec
            ln -s ${self.packages.${system}.kexec-bundle-test} $out/formats/kexec-bundle
            ${lib.optionalString (system == "aarch64-linux") ''
              ln -s ${self.packages.${system}.sd-aarch64-test} $out/formats/sd-aarch64
            ''}
            
            # Create manifest
            cat > $out/formats/manifest.json <<EOF
            {
              "formats": {
                "docker": "${self.packages.${system}.docker-test}",
                "iso": "${self.packages.${system}.install-iso-test}",
                "kexec": "${self.packages.${system}.kexec-test}",
                "kexec-bundle": "${self.packages.${system}.kexec-bundle-test}"
                ${lib.optionalString (system == "aarch64-linux") '',
                "sd-aarch64": "${self.packages.${system}.sd-aarch64-test}"
                ''}
              }
            }
            EOF
            
            # Wrap the test script with required tools
            wrapProgram $out/bin/test-all-formats \
              --prefix PATH : ${lib.makeBinPath (with pkgs; [
                nix
                coreutils
                bash
              ])}
          '';
        });

      # Formatter for your nix files
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

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

        # Format-specific configurations
        docker-test = mkFormatConfig {
          name = "docker";
          system = "x86_64-linux";
          formatConfig = baseFormatConfig.docker;
        };

        iso-test = mkFormatConfig {
          name = "install-iso";
          system = "x86_64-linux";
          formatConfig = baseFormatConfig.install-iso;
        };

        kexec-test = mkFormatConfig {
          name = "kexec";
          system = "x86_64-linux";
          formatConfig = baseFormatConfig.kexec;
        };

        sd-test = mkFormatConfig {
          name = "sd-aarch64";
          system = "aarch64-linux";
          formatConfig = baseFormatConfig.sd-aarch64;
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#ryzengrind@daimyo00'
      homeConfigurations = {
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

        # Format tests
        format-tests = import ./tests/format-tests.nix {
          inherit (nixpkgs.legacyPackages.${system}) pkgs;
          inherit self;
          formats = {
            docker = self.packages.${system}.docker-test;
            iso = self.packages.${system}.install-iso-test;
            kexec = self.packages.${system}.kexec-test;
            sd-aarch64 = self.packages.${system}.sd-aarch64-test;
          };
        };
      });
    };
}
