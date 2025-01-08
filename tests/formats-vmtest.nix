{
  pkgs,
  nixosModules,
  ...
}: let
  # Import the formats module
  formatsModule = ../modules/nixos/formats.nix;

  # Test network configuration
  testNetwork = {
    hostAddress = "192.168.1.1";
    netmask = "255.255.255.0";
    subnet = "192.168.1.0";
    clientAddress = "192.168.1.2";
  };
in pkgs.nixosTest {
  name = "formats-test";

  nodes = {
    # Test VM formats
    vmware-machine = { config, pkgs, ... }: {
      imports = [
        formatsModule
        nixosModules.default
      ];
      formatConfigs.vmware = {
        services.openssh.enable = true;
      };
    };

    virtualbox-machine = { config, pkgs, ... }: {
      imports = [
        formatsModule
        nixosModules.default
      ];
      formatConfigs.virtualbox = {
        services.openssh.enable = true;
      };
    };

    # Test container format
    docker-machine = { config, pkgs, ... }: {
      imports = [
        formatsModule
        nixosModules.default
      ];
      formatConfigs.docker = {
        services.openssh.enable = false;
      };
      virtualisation.docker.enable = true;
    };

    # Test installation media format
    iso-machine = { config, pkgs, ... }: {
      imports = [
        formatsModule
        nixosModules.default
      ];
      formatConfigs.iso = {
        services.openssh.enable = true;
      };
    };

    # Enhanced USB installer with PXE boot capabilities
    usb-installer = { config, pkgs, modulesPath, ... }: {
      imports = [
        formatsModule
        nixosModules.default
        "${toString modulesPath}/installer/cd-dvd/installation-cd-base.nix"
        "${toString modulesPath}/installer/netboot/netboot.nix"
      ];
      
      formatConfigs.iso = {
        services.openssh.enable = true;
      };

      # USB installer specific configuration
      isoImage = {
        makeUsbBootable = true;
        appendToMenuLabel = " USB Installer";
      };

      # PXE boot server configuration
      services.tftp = {
        enable = true;
        directory = "/srv/tftp";
      };

      services.dhcpd4 = {
        enable = true;
        interfaces = [ "eth0" ];
        extraConfig = ''
          option subnet-mask ${testNetwork.netmask};
          option broadcast-address 192.168.1.255;
          option routers ${testNetwork.hostAddress};
          option domain-name-servers ${testNetwork.hostAddress};
          
          subnet ${testNetwork.subnet} netmask ${testNetwork.netmask} {
            range ${testNetwork.clientAddress} ${testNetwork.clientAddress};
            filename "pxelinux.0";
            next-server ${testNetwork.hostAddress};
          }
        '';
        declarations = [
          ''
            allow booting;
            allow bootp;
          ''
        ];
      };

      networking = {
        useDHCP = false;
        interfaces.eth0.ipv4.addresses = [{
          address = testNetwork.hostAddress;
          prefixLength = 24;
        }];
        firewall = {
          allowedTCPPorts = [ 69 67 68 ]; # TFTP and DHCP ports
          allowedUDPPorts = [ 69 67 68 ];
        };
      };

      # Enhanced installation tools
      environment.systemPackages = with pkgs; [
        parted
        gparted
        dosfstools
        ntfs3g
        nixos-install-tools
        pxelinux
        syslinux
        dnsmasq # For PXE boot support
        nfs-utils
      ];

      # Enable NFS server for network installation
      services.nfs.server = {
        enable = true;
        exports = ''
          /srv/nfs *(ro,no_subtree_check,no_root_squash)
        '';
      };

      # Setup PXE boot environment
      system.activationScripts.setupPXE = ''
        mkdir -p /srv/tftp/pxelinux.cfg
        mkdir -p /srv/nfs
        cp ${pkgs.pxelinux}/share/syslinux/pxelinux.0 /srv/tftp/
        cp ${pkgs.pxelinux}/share/syslinux/ldlinux.c32 /srv/tftp/
        cp ${pkgs.pxelinux}/share/syslinux/menu.c32 /srv/tftp/
        
        # Create default PXE boot menu
        cat > /srv/tftp/pxelinux.cfg/default << EOF
        DEFAULT menu.c32
        PROMPT 0
        TIMEOUT 300
        ONTIMEOUT local
        
        MENU TITLE NixOS PXE Boot Menu
        
        LABEL nixos
          MENU LABEL NixOS Installer
          KERNEL /nixos/kernel
          APPEND initrd=/nixos/initrd init=/nix/store/*/init ${toString config.boot.kernelParams} root=/dev/nfs nfsroot=${testNetwork.hostAddress}:/srv/nfs
        
        LABEL local
          MENU LABEL Local Boot
          LOCALBOOT 0
        EOF
      '';

      # Enable hardware detection
      services.hardware.enableAllFirmware = true;
      hardware.enableRedistributableFirmware = true;

      # Enable live system features
      services.getty.autologinUser = "nixos";
      users.users.nixos.isNormalUser = true;
      users.users.nixos.extraGroups = [ "wheel" "networkmanager" ];
      users.users.nixos.initialPassword = "nixos";
      security.sudo.wheelNeedsPassword = false;
    };

    # Add PXE client for testing
    pxe-client = { config, pkgs, ... }: {
      imports = [
        formatsModule
        nixosModules.default
      ];

      virtualisation = {
        graphics = false;
        qemu.networkingOptions = [
          "-net nic,model=virtio"
          "-net user"
        ];
      };
    };
  };

  testScript = ''
    start_all()

    # Test common configuration across all formats
    with subtest("Test common configuration across formats"):
        for machine in ["vmware-machine", "virtualbox-machine", "iso-machine"]:
            machine = globals()[machine]  # Get machine reference
            
            # Test SSH configuration
            machine.wait_for_unit("sshd.service")
            machine.succeed("systemctl is-active sshd")
            
            # Test basic networking
            machine.wait_for_unit("network.target")
            machine.succeed("ping -c 1 8.8.8.8")
            
            # Test firewall configuration
            machine.succeed("systemctl is-active firewall.service")
            machine.succeed("iptables -L | grep 'tcp dpt:ssh'")
            
            # Test basic system packages
            for pkg in ["vim", "git", "curl", "wget"]:
                machine.succeed(f"which {pkg}")

    # Test VMware specific configuration
    with subtest("Test VMware configuration"):
        vmware-machine.succeed("test -e /etc/vmware-tools")
        vmware-machine.succeed("systemctl is-active sshd")

    # Test VirtualBox specific configuration
    with subtest("Test VirtualBox configuration"):
        virtualbox-machine.succeed("test -e /etc/virtualbox")
        virtualbox-machine.succeed("systemctl is-active sshd")

    # Test Docker specific configuration
    with subtest("Test Docker configuration"):
        docker-machine.wait_for_unit("docker.service")
        docker-machine.succeed("docker ps")
        # Verify SSH is disabled as per configuration
        docker-machine.fail("systemctl is-active sshd")

    # Test ISO specific configuration
    with subtest("Test ISO configuration"):
        iso-machine.succeed("test -e /etc/nixos")
        iso-machine.succeed("systemctl is-active sshd")

    # Test boot configuration
    with subtest("Test boot configuration"):
        for machine in ["vmware-machine", "virtualbox-machine", "iso-machine"]:
            machine = globals()[machine]
            machine.succeed("test -e /boot/efi")
            machine.succeed("bootctl status")

    # Verify format configurations are properly set
    with subtest("Verify format configurations"):
        # VMware format
        result = vmware-machine.succeed("nixos-option formatConfigs.vmware.formatAttr")
        assert "vmware" in result, f"Expected VMware format attribute, got {result}"
        
        # VirtualBox format
        result = virtualbox-machine.succeed("nixos-option formatConfigs.virtualbox.formatAttr")
        assert "virtualBoxOVA" in result, f"Expected VirtualBox format attribute, got {result}"
        
        # Docker format
        result = docker-machine.succeed("nixos-option formatConfigs.docker.formatAttr")
        assert "dockerImage" in result, f"Expected Docker format attribute, got {result}"
        
        # ISO format
        result = iso-machine.succeed("nixos-option formatConfigs.iso.formatAttr")
        assert "isoImage" in result, f"Expected ISO format attribute, got {result}"

    # Test USB installer specific configuration
    with subtest("Test USB installer configuration"):
        # Test basic system access
        usb-installer.wait_for_unit("multi-user.target")
        usb-installer.succeed("su - nixos -c 'echo $HOME'")
        
        # Test sudo access
        usb-installer.succeed("su - nixos -c 'sudo -n true'")
        
        # Test installation tools
        for tool in ["parted", "gparted", "mkfs.fat", "mkfs.ntfs", "nixos-install"]:
            usb-installer.succeed(f"which {tool}")
        
        # Test hardware detection
        usb-installer.succeed("ls -la /sys/class/firmware")
        usb-installer.succeed("ls -la /sys/class/net")
        
        # Test bootloader configuration
        usb-installer.succeed("test -e /boot/grub/grub.cfg")
        
        # Test partition management
        usb-installer.succeed("parted --version")
        usb-installer.succeed("lsblk")
        
        # Test network configuration tools
        usb-installer.succeed("networkctl list")
        usb-installer.succeed("nmcli device status")

    # Test installer media creation
    with subtest("Test installer media creation"):
        # Verify ISO configuration
        result = usb-installer.succeed("nixos-option isoImage.makeUsbBootable")
        assert "true" in result, "USB bootable option should be enabled"
        
        # Check for essential installer files
        usb-installer.succeed("test -e /etc/nixos")
        usb-installer.succeed("test -d /nix/store")
        
        # Verify installer scripts
        usb-installer.succeed("test -e /run/current-system/sw/bin/nixos-install")
        usb-installer.succeed("test -e /run/current-system/sw/bin/nixos-generate-config")
        
        # Test configuration generation
        usb-installer.succeed("su - nixos -c 'nixos-generate-config --show-hardware-config'")

    # Test PXE boot server configuration
    with subtest("Test PXE boot server configuration"):
        # Test TFTP service
        usb-installer.wait_for_unit("tftp.service")
        usb-installer.succeed("systemctl is-active tftp")
        
        # Test DHCP service
        usb-installer.wait_for_unit("dhcpd4.service")
        usb-installer.succeed("systemctl is-active dhcpd4")
        
        # Test NFS service
        usb-installer.wait_for_unit("nfs-server.service")
        usb-installer.succeed("systemctl is-active nfs-server")
        
        # Verify PXE boot files
        usb-installer.succeed("test -e /srv/tftp/pxelinux.0")
        usb-installer.succeed("test -e /srv/tftp/pxelinux.cfg/default")
        usb-installer.succeed("test -e /srv/tftp/menu.c32")
        
        # Test network configuration
        usb-installer.succeed(f"ip addr show eth0 | grep '{testNetwork.hostAddress}'")
        usb-installer.succeed("netstat -tulpn | grep ':69'")  # TFTP
        usb-installer.succeed("netstat -tulpn | grep ':67'")  # DHCP
        
        # Test firewall configuration
        for port in [69, 67, 68]:
            usb-installer.succeed(f"iptables -L | grep 'tcp dpt:{port}'")
            usb-installer.succeed(f"iptables -L | grep 'udp dpt:{port}'")

    # Test PXE boot environment
    with subtest("Test PXE boot environment"):
        # Test NFS exports
        usb-installer.succeed("exportfs -v | grep '/srv/nfs'")
        
        # Verify boot menu configuration
        usb-installer.succeed("grep 'NixOS PXE Boot Menu' /srv/tftp/pxelinux.cfg/default")
        usb-installer.succeed("grep 'nfsroot=' /srv/tftp/pxelinux.cfg/default")
        
        # Test required packages
        for pkg in ["dnsmasq", "pxelinux", "nfs-utils"]:
            usb-installer.succeed(f"which {pkg}")

    print("All format tests, including USB installer and PXE boot tests, completed successfully!")
  '';
} 