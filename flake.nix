{
  description = "NixOS configuration with specialisations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprlock.url = "github:hyprwm/hyprlock";
    hypridle.url = "github:hyprwm/hypridle";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-wsl,
    hyprland,
    hyprlock,
    hypridle,
    nixos-hardware,
    attic,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (nixpkgs) lib;

    # Helper function to create host configurations
    mkHost = {
      name,
      modules ? [],
      features ? [],
      profileConfig ? {},
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs features;};
        modules =
          [
            # Core modules
            ./modules/core
            {
              core = {
                enable = true;
                system.enable = true;
                network.enable = true;
                spec.enable = true;
              };

              # Profile configuration
              profiles =
                lib.recursiveUpdate {
                  # Base profile configuration for all systems
                  base = {
                    enable = true;
                    security.enable = true;
                    nix = {
                      enable = true;
                      gc = {
                        enable = true;
                        dates = "weekly";
                      };
                    };
                  };
                }
                profileConfig;
            }

            # Input modules
            home-manager.nixosModules.home-manager
            nixos-wsl.nixosModules.wsl
            hyprland.nixosModules.default
            ({config, ...}: {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.ryzengrind = {
                  imports = [
                    (
                      if hyprlock ? homeManagerModules
                      then hyprlock.homeManagerModules.default
                      else {}
                    )
                    (
                      if hypridle ? homeManagerModules
                      then hypridle.homeManagerModules.default
                      else {}
                    )
                  ];
                  programs = {
                    hyprlock.enable = lib.mkDefault false;
                    hypridle.enable = lib.mkDefault false;
                  };
                };
              };
            })

            # Profile system
            ./modules/profiles

            # Host-specific configuration
            (./hosts + "/${name}/configuration.nix")

            # Home-manager configuration
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.ryzengrind = import (./hosts + "/${name}/home.nix");
              };
            }
          ]
          ++ modules;
      };
  in {
    # NixOS configurations
    nixosConfigurations = {
      daimyo = mkHost {
        name = "daimyo";
        features = ["desktop" "development" "gaming"];
        profileConfig = {
          workstation.enable = true;
          gaming = {
            enable = true;
            nvidia = true;
            amd = false;
            virtualization = {
              enable = false;
              looking-glass = false;
            };
          };
          development = {
            enable = true;
            ide = "vscodium";
            vscodeRemote = {
              enable = true;
              method = "nix-ld";
            };
            ml = {
              enable = true;
              cudaSupport = true;
              pytorch = {
                enable = true;
              };
            };
          };
        };
        modules = [
          # Base configuration
          {
            programs = {
              hyprland.enable = lib.mkDefault false;
            };
            environment.systemPackages = with pkgs; [
              hyprland.packages.${system}.hyprland
              (
                if hyprlock ? packages
                then hyprlock.packages.${system}.default
                else {}
              )
              (
                if hypridle ? packages
                then hypridle.packages.${system}.default
                else {}
              )
            ];
          }
          # Import Hyprland module
          hyprland.nixosModules.default
          # Import hyprlock and hypridle as home-manager modules
          ({config, ...}: {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.ryzengrind = {
                imports = [
                  (
                    if hyprlock ? homeManagerModules
                    then hyprlock.homeManagerModules.default
                    else {}
                  )
                  (
                    if hypridle ? homeManagerModules
                    then hypridle.homeManagerModules.default
                    else {}
                  )
                ];
                programs = {
                  hyprlock.enable = lib.mkDefault false;
                  hypridle.enable = lib.mkDefault false;
                };
              };
            };
          })
        ];
      };

      daimyo00 = mkHost {
        name = "daimyo00";
        features = ["minimal" "development"];
        profileConfig = {
          development = {
            enable = true;
            ide = "vscodium";
            vscodeRemote = {
              enable = true;
              method = "nix-ld";
            };
            ml = {
              enable = false;
              cudaSupport = false;
              pytorch = {
                enable = false;
              };
            };
          };
          wsl.enable = true;
        };
        modules = [nixos-wsl.nixosModules.wsl];
      };
    };

    # Tests
    nixosTests = {
      core = pkgs.nixosTest {
        name = "core-system-test";
        nodes.machine = import ./tests/core/default.nix;
        testScript = builtins.readFile ./tests/core/test.py;
      };

      specialisation = pkgs.nixosTest {
        name = "specialisation-test";
        nodes.machine = import ./tests/specialisation/default.nix;
        testScript = builtins.readFile ./tests/specialisation/test.py;
      };
    };

    # Checks
    checks.${system} = {
      test-core = self.nixosTests.core.driver;
      test-specialisation = self.nixosTests.specialisation.driver;
      format = pkgs.runCommand "check-format" {} ''
        ${pkgs.alejandra}/bin/alejandra --check ${./.}
        touch $out
      '';
      statix = pkgs.runCommand "check-statix" {} ''
        ${pkgs.statix}/bin/statix check ${./.}
        touch $out
      '';
    };

    # Development shell
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nixfmt
        statix
        nil
        alejandra
        pre-commit
      ];
      shellHook = ''
        echo "Development environment ready"
      '';
    };

    # Formatter
    formatter.${system} = pkgs.alejandra;
  };
}
