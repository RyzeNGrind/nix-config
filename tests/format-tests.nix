# Format-specific tests
{ pkgs, self, formats }:

let
  inherit (pkgs) lib;
  
  # Helper function to test docker images
  testDocker = image: pkgs.vmTools.runInLinuxVM {
    inherit (pkgs) system;
    memSize = 1024;
    
    preVM = ''
      mkdir -p $out/nix-support
      touch $out/nix-support/hydra-build-products
    '';
    
    postVM = ''
      echo "docker" >> $out/nix-support/hydra-build-products
    '';
    
    buildInputs = with pkgs; [ docker ];
    
    script = ''
      # Start docker daemon
      dockerd &
      sleep 5
      
      # Load and test the image
      docker load < ${image}
      docker images
      
      # Try to run the container
      docker run --rm $(docker images -q | head -n1) echo "Container test successful"
    '';
  };
  
  # Helper function to test ISO images
  testISO = iso: pkgs.vmTools.runInLinuxVM {
    inherit (pkgs) system;
    memSize = 2048;
    
    preVM = ''
      mkdir -p $out/nix-support
      touch $out/nix-support/hydra-build-products
    '';
    
    postVM = ''
      echo "iso" >> $out/nix-support/hydra-build-products
    '';
    
    buildInputs = with pkgs; [ qemu ];
    
    script = ''
      # Test ISO boot in QEMU
      qemu-system-x86_64 \
        -m 1024 \
        -cdrom ${iso} \
        -nographic \
        -no-reboot \
        -serial mon:stdio
    '';
  };
  
  # Helper function to test kexec bundles
  testKexec = bundle: pkgs.runCommand "test-kexec" {
    buildInputs = [ pkgs.kexec-tools ];
  } ''
    # Verify bundle structure
    if [ ! -f ${bundle}/kernel ]; then
      echo "Kernel not found in kexec bundle"
      exit 1
    fi
    if [ ! -f ${bundle}/initrd ]; then
      echo "initrd not found in kexec bundle"
      exit 1
    fi
    
    # Test kexec load (dry run)
    kexec -l ${bundle}/kernel --initrd=${bundle}/initrd --reuse-cmdline -t
    
    mkdir -p $out/nix-support
    touch $out/nix-support/hydra-build-products
    echo "kexec" >> $out/nix-support/hydra-build-products
  '';
  
  # Helper function to test SD card images
  testSDImage = image: pkgs.runCommand "test-sd-image" {
    buildInputs = with pkgs; [ qemu ];
    nativeBuildInputs = with pkgs; [ util-linux ];
  } ''
    # Verify image format and structure
    qemu-img info ${image}
    
    # Try to mount the image (read-only)
    mkdir -p tmpmnt
    if [ -f ${image} ]; then
      # Get the start sector of the first partition
      SECTOR=$(fdisk -l ${image} | grep Linux | head -n1 | awk '{print $2}')
      OFFSET=$((SECTOR * 512))
      
      # Mount the first partition read-only
      mount -o ro,offset=$OFFSET ${image} tmpmnt
      
      # Check for basic files
      if [ ! -d tmpmnt/boot ]; then
        echo "No boot directory found"
        exit 1
      fi
      
      umount tmpmnt
    fi
    
    mkdir -p $out/nix-support
    touch $out/nix-support/hydra-build-products
    echo "sd-image" >> $out/nix-support/hydra-build-products
  '';

in {
  # Test docker image
  testDocker = testDocker formats.docker;
  
  # Test installation ISO
  testISO = testISO formats.iso;
  
  # Test kexec bundle
  testKexec = testKexec formats.kexec;
  
  # Test SD card image
  testSDImage = testSDImage formats.sd-aarch64;
} 