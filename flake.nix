{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: Add any other flake you might need
    hardware.url = "github:nixos/nixos-hardware";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, flake-utils, ... }@inputs:
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
      # Define apps at the top level for accessibility
      apps = forAllSystems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
        base = { lib, modulesPath, ... }: {
          imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];
          networking.nameservers = lib.mkIf pkgs.stdenv.isDarwin [ "8.8.8.8" ];
          virtualisation = {
            graphics = false;
            host = { inherit pkgs; };
          };
        };
        machine = nixpkgs.lib.nixosSystem {
          system = builtins.replaceStrings [ "darwin" ] [ "linux" ] system;
          modules = [ base ./nixos/configuration.nix ];
          services.getty.autologinUser = "root";
        };
        program = pkgs.writeShellScript "run-vm.sh" ''
          export NIX_DISK_IMAGE=$(mktemp -u -t nixos.qcow2)
          trap "rm -f $NIX_DISK_IMAGE" EXIT
          ${machine.config.system.build.vm}/bin/run-nixos-vm
        '';
      in {
        default = {
          type = "app";
          program = "${program}";
        };
      });

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
      # Available through 'nixos-rebuild --flake .#daimyo00'
      nixosConfigurations = let
        initialConfig = { config, pkgs, ... }: {
          networking.firewall.allowedTCPPorts = [ 22 ]; # Open SSH port
          system.stateVersion = config.system.nixos.release;
          services.openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "yes";
              PasswordAuthentication = "yes";
            };
          };
        };

        sshConfig = { config, pkgs, ... }: {
          imports = [ initialConfig ];
          services.openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "prohibit-password";
              PasswordAuthentication = "no"; # Disable password authentication for security
              ChallengeResponseAuthentication = "no"; # Disable challenge-response authentication
            };
            usePAM = true; # Enable Pluggable Authentication Modules
            x11Forwarding = true; # Enable X11 forwarding for GUI applications over SSH
            printMotd = false; # Disable the message of the day as it's unnecessary
            clientAliveInterval = 120; # Set client alive interval to prevent timeout
            clientAliveCountMax = 3; # Set maximum number of client alive messages
            authorizedKeys.keys = let
              githubKeysUrl = "https://github.com/RyzeNGrind.keys";
              githubKeysSha256 = pkgs.lib.fileContents (pkgs.runCommandLocal "fetch-github-keys-sha" {} ''
                ${pkgs.curl}/bin/curl --silent ${githubKeysUrl} | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1 > $out
              '');
            in pkgs.fetchurl {
              url = githubKeysUrl;
              sha256 = githubKeysSha256;
            };
          };
        };
      in {
        # FIXME replace with your hostname
        daimyo00 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          system = "x86_64-linux"; # Explicitly set the system to resolve the error
          modules = [
            initialConfig
            # Include the WSL-specific module from nixos-wsl
            inputs.nixos-wsl.nixosModules.default
            ./modules/nixos-wsl/override-build-tarball.nix
            # > Our main nixos configuration file <
            ./hosts/daimyo00/configuration.nix
            
          ];
        };
        nixos-live = {
          specialArgs = { inherit inputs outputs; };
          system = "x86_64-linux";
          modules = [
            initialConfig
            # Include the WSL-specific module from nixos-wsl
            inputs.nixos-wsl.nixosModules.default
            ./modules/nixos-wsl/override-build-tarball.nix
            # > Our main nixos configuration file <
            ./nixos/configuration.nix
          ];
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
    };
}

