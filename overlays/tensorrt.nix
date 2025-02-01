final: prev: {
  cudaPackages = prev.cudaPackages // {
    tensorrt = prev.cudaPackages.tensorrt.overrideAttrs (oldAttrs: {
      version = "10.0.0";  # Update to latest version
      src = prev.fetchurl {
        url = "https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/secure/10.0/10.0.0/tensorrt-10.0.0.tar.gz";
        sha256 = ""; # You'll need to add the correct hash
      };
      buildInputs = oldAttrs.buildInputs ++ [
        prev.cudaPackages.cuda_cudart
        prev.cudaPackages.cudnn
      ];
    });
  };
} 