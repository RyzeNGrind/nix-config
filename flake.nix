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
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
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

    # Testing framework
    testing = import "${nixpkgs}/nixos/lib/testing-python.nix" {
      inherit system;
      inherit (pkgs) pkgs;
    };

    # Helper function to create test
    mkTest = test:
      testing.makeTest (
        {
          name = test.name or "nixos-test";
          nodes = test.nodes or {};
          testScript = test.testScript or "";
        }
        // test
      );

    # Define our own modules
    nixosModules = {
      # Core modules
      core-system = import ./modules/core/system.nix;
      core-spec = import ./modules/core/spec.nix;

      # Feature modules
      programs = import ./modules/programs;
      hardware = import ./modules/hardware;
      services = import ./modules/services;
      system = import ./modules/system;
      virtualisation = import ./modules/virtualisation;

      # WSL-specific modules
      wsl = import ./modules/wsl;

      # Testing modules
      testing = import ./modules/testing;

      # Home-manager modules
      home = import ./modules/home-manager;
    };

    # Common modules for all configurations
    commonModules = [
      # Core modules
      self.nixosModules.core-system
      self.nixosModules.core-spec

      # External modules
      home-manager.nixosModules.home-manager
      nixos-wsl.nixosModules.wsl
      hyprland.nixosModules.default
      (import "${hyprlock}/nix/module.nix")
      (import "${hypridle}/nix/module.nix")
      attic.nixosModules.atticd

      # Local modules
      self.nixosModules.programs
      self.nixosModules.hardware
      self.nixosModules.services
      self.nixosModules.system
      self.nixosModules.virtualisation
    ];
  in {
    # Export our modules
    inherit nixosModules;

    # NixOS configurations
    nixosConfigurations = {
      daimyo = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs self;
          inherit (inputs) nixpkgs home-manager;
        };
        modules =
          commonModules
          ++ [
            # Base configuration
            {
              core = {
                system = {
                  enable = true;
                  flakeInputs = inputs;
                  stateVersion = "24.05";
                };
                spec = {
                  enable = true;
                  wsl = {
                    enable = true;
                    cuda = true;
                    gui = true;
                  };
                  development = {
                    enable = true;
                    containers = true;
                    languages = ["python" "rust" "go" "node"];
                  };
                };
              };
            }

            # Machine-specific configuration
            ./hosts/daimyo/configuration.nix

            # Home-manager configuration
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs self;
                  inherit (inputs) nixpkgs home-manager;
                };
                users.ryzengrind = import ./hosts/daimyo/home.nix;
              };
            }
          ];
      };
    };

    # Test configurations
    nixosTests = {
      # Core system tests
      core = pkgs.nixosTest {
        name = "core-system-test";

        nodes = {
          machine = {
            config,
            pkgs,
            lib,
            modulesPath,
            ...
          }:
            import ./tests/core/default.nix {
              inherit config pkgs lib inputs modulesPath;
            };
        };

        testScript = ''
          start_all()
          machine.wait_for_unit("multi-user.target")

          with subtest("System configuration tests"):
              # Test core system
              machine.succeed("test -d /nix")
              machine.succeed("test -d /etc")
              machine.succeed("nix --version")

          with subtest("Security hardening tests"):
              # Test basic security
              machine.succeed("systemctl status")
              machine.succeed("ps aux")
              machine.succeed("ulimit -n")

          with subtest("Network configuration tests"):
              # Test basic networking
              machine.succeed("ip addr show lo")
              machine.succeed("ip link show lo")
              machine.succeed("test -d /sys/class/net")

          with subtest("Package management tests"):
              # Test installed packages
              machine.succeed("which htop")
              machine.succeed("which python3.12")
              machine.succeed("which ip")
        '';
      };

      # Specialisation tests
      specialisation = mkTest {
        name = "specialisation-test";
        nodes = {
          machine = {
            config,
            pkgs,
            ...
          }:
            lib.mkMerge [
              {
                hardware = {
                  nvidia.package = pkgs.linuxPackages.nvidia_x11;
                  opengl = {
                    enable = true;
                    driSupport = true;
                    driSupport32Bit = true;
                  };
                };
              }
            ];
        };
        testScript = ''
          start_all()
          machine.wait_for_unit("multi-user.target")

          with subtest("WSL with CUDA tests"):
              # Test WSL environment
              machine.succeed("test -f /proc/sys/fs/binfmt_misc/WSLInterop")
              machine.succeed("test -e /dev/nvidia0")
              machine.succeed("nvidia-smi")
              machine.succeed("test -e /mnt/wslg")

          with subtest("WSL without CUDA tests"):
              # Test WSL environment without CUDA
              machine.succeed("test -f /proc/sys/fs/binfmt_misc/WSLInterop")
              machine.fail("test -e /dev/nvidia0")
              machine.fail("which nvidia-smi")

          with subtest("Baremetal tests"):
              # Test display manager
              machine.wait_for_unit("display-manager.service")

              # Test sound system
              machine.wait_for_unit("pipewire.service")
              machine.succeed("pactl info")

              # Test power management
              machine.succeed("systemctl is-active systemd-logind.service")
              machine.succeed("test -d /sys/class/power_supply")
        '';
      };

      # Architecture tests
      arch = mkTest {
        name = "architecture-test";
        nodes = {
          machine = {
            config,
            pkgs,
            ...
          }:
            lib.mkMerge [
              {
                virtualisation.memorySize = 4096;
                virtualisation.cores = 4;
              }
            ];
        };
        testScript = ''
          start_all()
          machine.wait_for_unit("multi-user.target")

          with subtest("CPU architecture tests"):
              # Test CPU features
              machine.succeed("grep -q 'sse4_2' /proc/cpuinfo")
              machine.succeed("grep -q 'avx2' /proc/cpuinfo")

              # Test CPU frequency scaling
              machine.succeed("test -d /sys/devices/system/cpu/cpu0/cpufreq")

              # Test CPU governor
              machine.succeed("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor | grep -q 'performance'")

          with subtest("Memory architecture tests"):
              # Test memory configuration
              machine.succeed("free -m")
              machine.succeed("test $(free -g | awk '/^Mem:/{print $2}') -ge 2")

              # Test huge pages
              machine.succeed("test -d /sys/kernel/mm/hugepages")
              machine.succeed("sysctl -n vm.nr_hugepages")

          with subtest("Storage architecture tests"):
              # Test block device configuration
              machine.succeed("lsblk")
              machine.succeed("test -d /sys/block")

              # Test filesystem support
              machine.succeed("grep -q 'ext4' /proc/filesystems")
              machine.succeed("grep -q 'btrfs' /proc/filesystems")

          with subtest("Network architecture tests"):
              # Test network interfaces
              machine.succeed("ip link show")
              machine.succeed("test -d /sys/class/net")

              # Test network protocols
              machine.succeed("test -f /proc/net/tcp")
              machine.succeed("test -f /proc/net/udp")
        '';
      };

      # Run all tests
      all = mkTest {
        name = "all-tests";
        nodes = {
          machine = {
            config,
            pkgs,
            lib,
            modulesPath,
            ...
          }:
            import ./tests/core/default.nix {
              inherit config pkgs lib inputs modulesPath;
            };
        };
        testScript = ''
          start_all()
          machine.wait_for_unit("multi-user.target")

          # Core tests
          with subtest("System configuration tests"):
              # Test core system
              machine.succeed("test -d /nix")
              machine.succeed("test -d /etc")
              machine.succeed("nix --version")

          with subtest("Security hardening tests"):
              # Test basic security
              machine.succeed("systemctl status")
              machine.succeed("ps aux")
              machine.succeed("ulimit -n")

          with subtest("Network configuration tests"):
              # Test basic networking
              machine.succeed("ip addr show lo")
              machine.succeed("ip link show lo")
              machine.succeed("test -d /sys/class/net")

          with subtest("Package management tests"):
              # Test installed packages
              machine.succeed("which htop")
              machine.succeed("which python3.12")
              machine.succeed("which ip")

          # Architecture tests
          with subtest("CPU architecture tests"):
              # Test CPU info
              machine.succeed("test -f /proc/cpuinfo")
              machine.succeed("grep -q 'processor' /proc/cpuinfo")

              # Test CPU topology
              machine.succeed("test -d /sys/devices/system/cpu")
              machine.succeed("test -d /sys/devices/system/cpu/cpu0")

          with subtest("Memory architecture tests"):
              # Test memory info
              machine.succeed("test -f /proc/meminfo")
              machine.succeed("grep -q 'MemTotal' /proc/meminfo")
              machine.succeed("free -m")

          with subtest("Storage architecture tests"):
              # Test block devices
              machine.succeed("test -d /sys/block")

              # Test filesystem info
              machine.succeed("test -f /proc/filesystems")
              machine.succeed("mount")

          with subtest("Network architecture tests"):
              # Test network stack
              machine.succeed("test -d /sys/class/net")
              machine.succeed("test -f /proc/net/tcp")
              machine.succeed("test -f /proc/net/udp")
              machine.succeed("ip link show")

          # WSL tests
          with subtest("WSL environment tests"):
              # Test WSL environment (should be disabled)
              machine.fail("test -f /proc/sys/fs/binfmt_misc/WSLInterop")
              machine.fail("test -e /dev/nvidia0")
              machine.fail("which nvidia-smi")
              machine.fail("test -e /mnt/wslg")
        '';
      };
    };

    # Checks for CI
    checks.${system} = {
      # Run tests
      test-core = self.nixosTests.core.driver;
      test-specialisation = lib.mapAttrs (name: test: test.driver) self.nixosTests.specialisation;
      test-arch = self.nixosTests.arch.driver;

      # Static analysis
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
        # Tool documentation
        echo "🛠️  Available development tools:"
        echo ""
        echo "  🔧 nixfmt - Nix code formatter"
        echo "    nixfmt <file>      Format a single file"
        echo "    nixfmt .           Format all .nix files recursively"
        echo ""
        echo "  ✨ statix - Lints and suggestions for Nix code"
        echo "    statix check       Check for issues"
        echo "    statix fix         Auto-fix common issues"
        echo "    statix report      Generate HTML report"
        echo ""
        echo "  🔍 nil - Nix language server"
        echo "    nil               Start language server"
        echo "    nil diagnostics   Show diagnostics"
        echo "    nil format        Format current file"
        echo ""
        echo "  💅 alejandra - Opinionated Nix formatter"
        echo "    alejandra <file>   Format a single file"
        echo "    alejandra .        Format all files in directory"
        echo "    alejandra --check  Check if files are formatted"
        echo ""
        echo "  🔄 pre-commit - Git hooks manager"
        echo "    pre-commit run     Run hooks on staged files"
        echo "    pre-commit run -a  Run hooks on all files"
        echo ""

        echo "  🔄 Git hooks"
        echo "    git config --local core.hooksPath .git/hooks/"
        echo "    pre-commit install --install-hooks"
        echo "    pre-commit install --hook-type commit-msg"
      '';
    };

    # Formatter configuration
    formatter.${system} = pkgs.alejandra;
  };
}
