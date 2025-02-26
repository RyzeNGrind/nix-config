# Virtualization features module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.core.features;
in {
  options.core.features = with lib; {
    virtualization = {
      docker.enable = mkEnableOption "Docker support";
      podman.enable = mkEnableOption "Podman support";
      kvm.enable = mkEnableOption "KVM/QEMU support";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.virtualization.docker.enable {
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        autoPrune.enable = true;
      };
      environment.systemPackages = with pkgs; [
        docker-compose
        lazydocker
      ];
      users.users.${config.user.name}.extraGroups = ["docker"];
    })

    (lib.mkIf cfg.virtualization.podman.enable {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      environment.systemPackages = with pkgs; [
        podman-compose
      ];
    })

    (lib.mkIf cfg.virtualization.kvm.enable {
      virtualisation = {
        libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            runAsRoot = true;
            swtpm.enable = true;
            ovmf = {
              enable = true;
              packages = with pkgs; [OVMFFull.fd];
            };
          };
        };
        spiceUSBRedirection.enable = true;
      };
      environment.systemPackages = with pkgs; [
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        win-virtio
        win-spice
      ];
      users.users.${config.user.name}.extraGroups = ["libvirtd" "kvm"];
    })
  ];
}
