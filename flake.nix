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
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            name = "nix-config";
            packages = with pkgs; [
              nixpkgs-fmt
              nil
              statix
              nixd
              alejandra
              nix-output-monitor
              git
              home-manager
              deadnix
              nixpkgs-lint
              _1password-cli
            ];
            shellHook = ''
              echo "Welcome to nix-config development shell"
              echo "Available tools: nixpkgs-fmt, nil, statix, nixd, alejandra, nom, git, home-manager"
              echo -e "\e[1;34mnixpkgs-fmt, deadnix, statix, and nixpkgs-lint are now available in this shell.\e[0m"
              echo -e "\e[1;34mUse 'nixpkgs-fmt <file or directory>' to format Nix code.\e[0m"
              echo -e "\e[1;34mUse 'statix check <file or directory>' to lint Nix code with statix.\e[0m"
              echo -e "\e[1;34mUse 'deadnix <file or directory>' to remove unused variables in Nix code.\e[0m"
              echo -e "\e[1;34mUse 'nixpkgs-lint <file or directory>' for additional linting of Nixpkgs specifics.\e[0m"
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
