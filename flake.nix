{
  description = "NixOS configurations for baremetal and WSL development/server/cluster environments";

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
    nixos-wsl.url = "github:nix-community/nixos-wsl";

    # Hardware configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    pre-commit-hooks,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Only build for Linux systems
    linuxSystems = ["x86_64-linux" "aarch64-linux"];
    # For packages that can build on any system
    allSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs allSystems;
    # Add this new overlay to make unstable packages available
    overlayUnstable = _: prev: {
      unstable = import nixpkgs-unstable {
        inherit (prev) system;
        config.allowUnfree = true;
      };
    };
  in {
    # Add checks for pre-commit hooks
    checks = forAllSystems (system: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra = {
            enable = true;
            excludes = ["^modules/nixos/cursor/.*$"];
            settings.verbosity = "quiet";
          };
          deadnix = {
            enable = true;
            excludes = ["^modules/nixos/cursor/.*$"];
            settings.noLambdaPatternNames = true;
          };
          statix = {
            enable = true;
            excludes = ["^modules/nixos/cursor/.*$"];
          };
          prettier = {
            enable = true;
            excludes = [
              "^modules/nixos/cursor/.*$"
              "^.vscode/settings.json$"
            ];
            types_or = [
              "markdown"
              "yaml"
              "json"
            ];
          };
          test-flake = {
            enable = true;
            name = "NixOS Configuration Tests";
            entry = "scripts/test-flake.sh";
            language = "system";
            pass_filenames = false;
            stages = ["commit"];
            always_run = true;
          };
        };
      };
    });

    # Your custom packages and modifications
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = system == "x86_64-linux" || system == "aarch64-linux";
          amdgpuSupport = system == "x86_64-linux" || system == "aarch64-linux";
          experimental-features = ["nix-command" "flakes" "repl-flake" "recursive-nix" "fetch-closure" "dynamic-derivations" "daemon-trust-override" "cgroups" "ca-derivations" "auto-allocate-uids" "impure-derivations"];
        };
      };
    in {
      default = pkgs.mkShell {
        name = "nix-config-dev-shell";
        nativeBuildInputs = with pkgs; [
          # Formatters and linters
          alejandra
          deadnix
          statix
          nodePackages.prettier

          # Git and pre-commit
          git
          pre-commit

          # Nix tools
          nixpkgs-fmt
          nil
          nix-output-monitor

          # Home Manager
          inputs.home-manager.packages.${system}.default

          # Shell tools
          starship
          bash
          bash-completion
          bash-preexec
          fzf
          zoxide
          direnv
        ];

        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;

        shellHook = ''
          # Set colors
          GREEN='\033[0;32m'
          BLUE='\033[0;34m'
          YELLOW='\033[1;33m'
          RED='\033[0;31m'
          NC='\033[0m'

          # Print welcome message
          echo -e "\n''${BLUE}Welcome to the NixOS Configuration Development Shell''${NC}"
          echo -e "''${YELLOW}Project: ClusterLab/nix-config''${NC}\n"

          # Display available tools
          echo -e "''${GREEN}Available Tools:''${NC}"
          echo -e "''${BLUE}Formatters & Linters:''${NC}"
          echo -e "  • alejandra    - Format Nix files"
          echo -e "  • deadnix      - Find dead code in Nix files"
          echo -e "  • statix       - Lint Nix files"
          echo -e "  • prettier     - Format other files"

          echo -e "\n''${BLUE}Git & Version Control:''${NC}"
          echo -e "  • git          - Version control"
          echo -e "  • pre-commit   - Run pre-commit hooks"

          echo -e "\n''${BLUE}Nix Tools:''${NC}"
          echo -e "  • nixpkgs-fmt  - Alternative Nix formatter"
          echo -e "  • nil          - Nix language server"
          echo -e "  • nom          - Nix output monitor"
          echo -e "  • home-manager - User environment manager"

          echo -e "\n''${BLUE}Common Commands:''${NC}"
          echo -e "  • ./scripts/test-flake.sh                                  - Run basic tests"
          echo -e "  • RUN_SYSTEM_TEST=1 RUN_HOME_TEST=1 ./scripts/test-flake.sh - Run comprehensive tests"
          echo -e "  • nix flake check                                         - Check flake integrity"
          echo -e "  • home-manager switch                                     - Update user environment"
          echo -e "  • nixos-rebuild test --flake .                           - Test system configuration"
          echo -e "  • pre-commit run --all-files                             - Run all pre-commit hooks"

          echo -e "\n''${BLUE}Development Workflow:''${NC}"
          echo -e "1. Make changes to configuration files"
          echo -e "2. Run formatters (alejandra, prettier)"
          echo -e "3. Run pre-commit hooks"
          echo -e "4. Test changes with test-flake.sh"
          echo -e "5. Rebuild system to apply changes"

          # Ensure TMPDIR exists and has correct permissions
          if [ -w /tmp ]; then
            export TMPDIR="/tmp"
          else
            export TMPDIR="$HOME/.cache/tmp"
            mkdir -p "$TMPDIR"
          fi

          # Configure git for better WSL performance
          git config --local core.fsmonitor false
          git config --local core.untrackedcache false

          # Create custom pre-commit hook
          mkdir -p .git/hooks
          cat > .git/hooks/pre-commit << 'EOF'
          #!/usr/bin/env bash
          set -e

          # Helper function to check if we're in a Nix shell
          in_nix_shell() {
            [[ -n "$IN_NIX_SHELL" ]] || [[ -n "$NIX_SHELL_ACTIVE" ]]
          }

          # Check if we're in the development shell
          if ! in_nix_shell; then
            echo -e "\033[1;33mWarning: Not in development shell. Running git commit outside of development shell may skip hooks.\033[0m"
            echo -e "\033[1;33mPlease run 'nix develop' first.\033[0m"
            exit 1
          fi

          # Use pre-commit from the development shell
          if ! command -v pre-commit >/dev/null 2>&1; then
            echo -e "\033[1;31mError: pre-commit command not found. Are you in the development shell?\033[0m"
            exit 1
          fi

          exec pre-commit run --config .pre-commit-config.yaml --hook-type pre-commit
          EOF

          chmod +x .git/hooks/pre-commit

          # Export shell indicator
          export NIX_SHELL_ACTIVE=1

          # Set up bash shell environment
          mkdir -p ~/.bashrc.d
          cat > ~/.bashrc.d/nix-develop.bash << EOF
          # Initialize starship
          if command -v starship >/dev/null; then
            eval "\$(starship init bash)"
          fi

          # Initialize direnv
          if command -v direnv >/dev/null; then
            eval "\$(direnv hook bash)"
          fi

          # Initialize zoxide
          if command -v zoxide >/dev/null; then
            eval "\$(zoxide init bash)"
          fi

          # Enable bash completion
          if [ -f /usr/share/bash-completion/bash_completion ]; then
            . /usr/share/bash-completion/bash_completion
          elif [ -f /etc/bash_completion ]; then
            . /etc/bash_completion
          fi
          EOF

          # Run initial pre-commit check
          pre-commit run --all-files || true

          echo -e "\n''${GREEN}Development shell activated with pre-commit hooks''${NC}"
          echo -e "''${YELLOW}Type 'exit' to leave the shell''${NC}\n"
        '';
      };
    });

    # Rest of your flake outputs...
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = system == "x86_64-linux" || system == "aarch64-linux";
          amdgpuSupport = system == "x86_64-linux" || system == "aarch64-linux";
        };
      };

      # Create empty derivation with explicit structure
      emptyDrv = derivation {
        name = "empty";
        inherit system;
        builder = "${pkgs.bash}/bin/bash";
        args = ["-c" "mkdir -p $out"];
      };

      # Create TensorRT package based on system support
      tensorrtPkg =
        if (builtins.elem system linuxSystems)
        then (pkgs.callPackage ./pkgs/tensorrt {inherit (pkgs) cudaPackages;})
        else emptyDrv;
    in {
      default = tensorrtPkg;
      tensorrt = tensorrtPkg;
    });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays =
      import ./overlays {inherit inputs;}
      // {
        unstable = overlayUnstable;
      };
    nixosModules = let
      moduleList = import ./modules/nixos;
    in {
      # Re-export core modules individually
      inherit (moduleList) core features profiles default;

      # Additional module combinations
      all = {...}: {
        imports = with moduleList; [
          core
          features
          profiles
        ];
      };
    };

    # NixOS configuration entrypoint
    nixosConfigurations = {
      # Workstation WSL configuration
      nix-ws = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          # Core modules
          self.nixosModules.default
          ./hosts/nix-ws/configuration.nix

          # Global configuration
          {
            nixpkgs.config = {
              allowBroken = true;
              allowUnfree = true;
            };
            nix.settings = {
              substituters = [
                "https://cache.nixos.org"
                "https://cuda-maintainers.cachix.org"
                "https://nix-community.cachix.org"
              ];
              trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
              accept-flake-config = true;
            };
          }

          # Home Manager module
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.ryzengrind = import ./hosts/nix-ws/home.nix;
              extraSpecialArgs = {inherit inputs outputs;};
            };
          }
        ];
      };

      # Surface Book 3 WSL configuration
      nix-pc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          # Core modules
          self.nixosModules.default
          ./hosts/nix-pc/configuration.nix

          # Global configuration
          {
            nixpkgs = {
              config = {
                allowBroken = true;
                allowUnfree = true;
              };
              overlays = [
                outputs.overlays.unstable
              ];
            };
            nix.settings = {
              substituters = [
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
              ];
              trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
            };
          }

          # Home Manager module
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.ryzengrind = import ./hosts/nix-pc/home.nix;
              extraSpecialArgs = {inherit inputs outputs;};
            };
          }
        ];
      };

      # Test configuration
      test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          # Base configuration
          self.nixosModules.default
          ./hosts/wsl/default.nix

          # Test-specific settings
          {
            users.users.ryzengrind = {
              isNormalUser = true;
              extraGroups = ["wheel"];
            };
          }
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    homeConfigurations = {
      "ryzengrind@nix-ws" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./hosts/nix-ws/home.nix
        ];
      };

      "ryzengrind@nix-pc" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./hosts/nix-pc/home.nix
        ];
      };
    };
  };
}
