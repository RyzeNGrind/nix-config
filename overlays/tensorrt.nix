final: prev: {
  cudaPackages = prev.cudaPackages.overrideScope (final': prev': {
    # TensorRT 10.8 variants for x86_64
    tensorrt_10_8_cuda11 = prev'.tensorrt.overrideAttrs (oldAttrs: {
      version = "10.8.0.43";
      src = final.requireFile {
        name = "TensorRT-10.8.0.43.Linux.x86_64-gnu.cuda-11.8.tar.gz";
        url = "https://developer.nvidia.com/tensorrt";
        sha256 = "661749f5951a9ce490dd36ca34422f4be7c72d0f935d9f9276b50be1488447e9";
      };
    });

    tensorrt_10_8_cuda12 = prev'.tensorrt.overrideAttrs (oldAttrs: {
      version = "10.8.0.43";
      src = final.requireFile {
        name = "TensorRT-10.8.0.43.Linux.x86_64-gnu.cuda-12.8.tar.gz";
        url = "https://developer.nvidia.com/tensorrt";
        sha256 = "577d6d8af538153414b9867c666b4f65852fc2eb1e7c0ea3a206e5fafbc7d49e";
      };
    });

    # TensorRT 10.8 for aarch64
    tensorrt_10_8_arm64 = prev'.tensorrt.overrideAttrs (oldAttrs: {
      version = "10.8.0.43";
      src = final.requireFile {
        name = "TensorRT-10.8.0.43.Linux.aarch64-gnu.cuda-12.8.tar.gz";
        url = "https://developer.nvidia.com/tensorrt";
        sha256 = "b01e5dd2c7c643252119d03d92eea97023418e92f45a3be0d0896e962923e43a";
      };
    });

    # TensorRT 8.6 variants for x86_64
    tensorrt_8_6_cuda11 = prev'.tensorrt.overrideAttrs (oldAttrs: {
      version = "8.6.1.6";
      src = final.requireFile {
        name = "TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-11.8.tar.gz";
        url = "https://developer.nvidia.com/tensorrt";
        sha256 = "e17e363bc1b738925ec9ad7e92c4cd52408acfa908811154803609d825ba2a35";
      };
    });

    tensorrt_8_6_cuda12 = prev'.tensorrt.overrideAttrs (oldAttrs: {
      version = "8.6.1.6";
      src = final.requireFile {
        name = "TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-12.0.tar.gz";
        url = "https://developer.nvidia.com/tensorrt";
        sha256 = "506142487f94b6cad6f13953e59bb9b7cd9b2e1bfbb01f99498cbedf2a6ce0a7";
      };
    });

    # TensorRT 8.6 for aarch64
    tensorrt_8_6_arm64 = prev'.tensorrt.overrideAttrs (oldAttrs: {
      version = "8.6.1.6";
      src = final.requireFile {
        name = "TensorRT-8.6.1.6.Ubuntu-20.04.aarch64-gnu.cuda-12.0.tar.gz";
        url = "https://developer.nvidia.com/tensorrt";
        sha256 = "ee81c6aa98cb7157a0479b9034c6dcf22f4e220a5b032eaf62aab8d048719dd2";
      };
    });

    # Set default tensorrt to latest stable x86_64 version
    tensorrt = final'.tensorrt_10_8_cuda12;
  });
} 