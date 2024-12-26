{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: Add any other flake you might need
    hardware.url = "github:nixos/nixos-hardware";
    nixos-wsl.url = "github:nix-community/nixos-wsl";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, ... }@inputs:
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
    in {
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      packages =
        forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      
      # Development shells
      devShells = forAllSystems (system:
        let 
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
                "1password"
                "1password-cli"
              ];
            };
          };
          
          # Create a custom package set for 1Password
          onepassword = pkgs.symlinkJoin {
            name = "1password-combined";
            paths = with pkgs; [ _1password-cli ];
            buildInputs = with pkgs; [ makeWrapper ];
            postBuild = ''
              # Ensure proper runtime environment
              wrapProgram $out/bin/op \
                --set NIXPKGS_ALLOW_UNFREE 1
            '';
          };
          
        in {
          default = pkgs.mkShell {
            name = "nix-config";
            
            packages = with pkgs; [
              # Nix development tools
              nixpkgs-fmt
              nil
              statix
              nixd
              alejandra
              nix-output-monitor
              deadnix
              
              # Version control
              git
              gh
              
              # System tools
              home-manager
              
              # Build tools
              gnumake
              just
              
              # CI/CD tools
              act # For testing GitHub Actions locally
              
              # Secrets management
              sops
              age
              ssh-to-age
            ];
            
            # Add 1Password separately
            nativeBuildInputs = [ onepassword ];
            
            # Environment variables
            shellHook = ''
              # Allow unfree packages
              export NIXPKGS_ALLOW_UNFREE=1
              export NIXPKGS_ALLOW_INSECURE=1
              
              # 1Password CLI configuration
              export OP_BIOMETRIC_UNLOCK_ENABLED=true
              export OP_PLUGIN_TIMEOUT=3600
              
              # GitHub Actions configuration
              if [ -n "$GITHUB_ACTIONS" ] && [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
                echo "Using 1Password Service Account for GitHub Actions"
              fi
              
              echo -e "\033[1;32mWelcome to nix-config development shell\033[0m"
              echo -e "\033[1;34mAvailable tools:\033[0m"
              echo -e "  • \033[1;33mnixpkgs-fmt\033[0m : Format Nix code"
              echo -e "  • \033[1;33mnil\033[0m        : Nix language server"
              echo -e "  • \033[1;33mstatix\033[0m     : Static analysis for Nix"
              echo -e "  • \033[1;33mnixd\033[0m       : Nix daemon tools"
              echo -e "  • \033[1;33malejandra\033[0m  : Alternative Nix formatter"
              echo -e "  • \033[1;33mnom\033[0m        : Nix output monitor"
              echo -e "  • \033[1;33mdeadnix\033[0m    : Find dead code"
              echo -e "  • \033[1;33mjust\033[0m       : Command runner"
              echo -e "  • \033[1;33m1password\033[0m  : Secrets management (CLI)"
              echo -e "  • \033[1;33mact\033[0m        : Test GitHub Actions locally"
              echo -e "  • \033[1;33mgh\033[0m         : GitHub CLI"
              echo -e "  • \033[1;33msops\033[0m       : Secrets encryption"
              echo -e "\033[1;36mTip: Use 'nom build' instead of 'nix build' for better output\033[0m"
              echo -e "\033[1;36mTip: Use 'op' command for 1Password CLI operations\033[0m"
              echo -e "\033[1;36mTip: Use 'act' to test GitHub Actions locally\033[0m"
              
              # Setup local GitHub Actions environment if needed
              if command -v act &> /dev/null; then
                echo -e "\033[1;36mTip: Create .secrets file with your 1Password service account token to test GitHub Actions:\033[0m"
                echo -e "  echo 'OP_SERVICE_ACCOUNT_TOKEN=your_token_here' > .secrets"
              fi
            '';
          };
        }
      );

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
      # Available through 'nixos-rebuild --flake .#daimyo00'
      nixosConfigurations = {
        # FIXME replace with your hostname
        daimyo00 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          system = "x86_64-linux"; # Explicitly set the system to resolve the error
          modules = [
            # Include the WSL-specific module from nixos-wsl
            inputs.nixos-wsl.nixosModules.default
            #./modules/nixos-wsl/override-build-tarball.nix
            # > Our main nixos configuration file <
            ./hosts/daimyo00/configuration.nix
          ];
        };
      };

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
    };
}
