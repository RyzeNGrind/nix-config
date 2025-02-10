{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    # You can access packages and modules from different nixpkgs revs
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pre-commit hooks
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-WSL
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Git hooks
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, git-hooks, nixos-wsl, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
    in
    {
      devShells = forAllSystems (system: let
        pkgs = nixpkgsFor.${system};
      in {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            pre-commit
            nixfmt
            statix
            deadnix
            nodePackages.prettier
            python3Packages.black
            shellcheck
          ];
          shellHook = ''
            # Create git hooks directory
            mkdir -p .git/hooks
            
            # Create pre-commit hook
            cat > .git/hooks/pre-commit << 'EOF'
            #!/usr/bin/env bash
            set -e
            
            # Run formatters
            ${pkgs.nixfmt}/bin/nixfmt $(git diff --cached --name-only --diff-filter=ACM | grep '\.nix$' || true)
            ${pkgs.statix}/bin/statix check .
            ${pkgs.deadnix}/bin/deadnix $(git diff --cached --name-only --diff-filter=ACM | grep '\.nix$' || true)
            ${pkgs.nodePackages.prettier}/bin/prettier --write $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(md|yml|yaml|json)$' || true)
            ${pkgs.python3Packages.black}/bin/black $(git diff --cached --name-only --diff-filter=ACM | grep '\.py$' || true)
            ${pkgs.shellcheck}/bin/shellcheck --severity=warning $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(sh|bash)$' || true)
            
            # Stage formatted files
            git add $(git diff --cached --name-only --diff-filter=ACM || true)
            EOF
            
            # Make pre-commit hook executable
            chmod +x .git/hooks/pre-commit
            
            echo "Git hooks installed successfully"
          '';
        };
      });

      # Packages that can build on any system
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = system == "x86_64-linux" || system == "aarch64-linux";
            };
          };

          # Create empty derivation with explicit structure
          emptyDrv = derivation {
            name = "empty";
            inherit system;
            builder = "${pkgs.bash}/bin/bash";
            args = [
              "-c"
              "mkdir -p $out"
            ];
          };

          # Create TensorRT package based on system support
          tensorrtPkg =
            if (builtins.elem system supportedSystems) then
              (pkgs.callPackage ./pkgs/tensorrt { inherit (pkgs) cudaPackages; })
            else
              emptyDrv;
        in
        {
          default = tensorrtPkg;
          tensorrt = tensorrtPkg;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./modules/nixos;

      # NixOS configuration entrypoint
      nixosConfigurations = {
        # WSL configuration
        daimyo00 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
          };
          modules = [
            # WSL module
            nixos-wsl.nixosModules.wsl

            # Base configuration
            ./hosts/daimyo00/configuration.nix

            # Home Manager module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs self;
              };
              home-manager.users.ryzengrind = import ./hosts/daimyo00/home.nix;
            }
          ];
        };

        # No CUDA/TensorRT configuration
        daimyo00-nocuda = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
          };
          modules = [
            # WSL module
            nixos-wsl.nixosModules.wsl

            # Base configuration
            ./hosts/daimyo00/configuration.nix

            # Home Manager module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs self;
              };
              home-manager.users.ryzengrind = import ./hosts/daimyo00/home.nix;
            }

            # Disable CUDA
            ({ config, pkgs, ... }: {
              profiles.dev.ml.cudaSupport = false;
            })
          ];
        };

        # Minimal test configuration
        daimyo00-test = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs self;
          };
          modules = [
            # WSL module
            nixos-wsl.nixosModules.wsl

            # Base configuration
            ./hosts/daimyo00/configuration.nix

            # Home Manager module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs self;
              };
              home-manager.users.ryzengrind = import ./hosts/daimyo00/home.nix;
            }
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      homeConfigurations = {
        "ryzengrind@daimyo00" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs self;
          };
          modules = [ ./hosts/daimyo00/home.nix ];
        };
      };
    };
}
