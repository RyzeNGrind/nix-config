# Format-specific tests
{ pkgs, self, formats }:

let
  inherit (pkgs) lib;
  
  # Helper function to test docker images
  testDocker = image: pkgs.vmTools.runInLinux {
    inherit (pkgs) system;
    memSize = 1024;
    
    preVM = ''
      mkdir -p $out/nix-support
      touch $out/nix-support/hydra-build-products
    '';
    
    postVM = ''
      echo "docker" >> $out/nix-support/hydra-build-products
    '';
    
    buildInputs = [ pkgs.docker ];
    
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
  testISO = iso: pkgs.vmTools.runInLinux {
    inherit (pkgs) system;
    memSize = 2048;
    
    preVM = ''
      mkdir -p $out/nix-support
      touch $out/nix-support/hydra-build-products
    '';
    
    postVM = ''
      echo "iso" >> $out/nix-support/hydra-build-products
    '';
    
    buildInputs = [ pkgs.qemu ];
    
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
  testKexec = bundle: pkgs.runCommand "test-kexec" {} ''
    # Verify bundle structure
    if [ ! -f ${bundle}/kernel ]; then
      echo "Kernel not found in kexec bundle"
      exit 1
    fi
    if [ ! -f ${bundle}/initrd ]; then
      echo "initrd not found in kexec bundle"
      exit 1
    fi
    
    mkdir -p $out/nix-support
    touch $out/nix-support/hydra-build-products
    echo "kexec" >> $out/nix-support/hydra-build-products
  '';
  
  # Helper function to test SD card images
  testSDImage = image: pkgs.runCommand "test-sd-image" {} ''
    # Verify image format and structure
    ${pkgs.qemu}/bin/qemu-img info ${image}
    
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