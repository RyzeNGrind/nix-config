# TensorRT overlay with multi-version, multi-arch support
_final: prev: {
  tensorrt = rec {
    # Direct package access
    tensorrt_10_8_cuda11 = prev.callPackage ../pkgs/tensorrt/generic.nix {
      version = "10.8.0.43";
      cudaVersion = "11.8";
      arch = "x86_64-gnu";
      sha256 = "661749f5951a9ce490dd36ca34422f4be7c72d0f935d9f9276b50be1488447e9";
    };

    tensorrt_10_8_cuda12 = prev.callPackage ../pkgs/tensorrt/generic.nix {
      version = "10.8.0.43";
      cudaVersion = "12.8";
      arch = "x86_64-gnu";
      sha256 = "577d6d8af538153414b9867c666b4f65852fc2eb1e7c0ea3a206e5fafbc7d49e";
    };

    tensorrt_10_8_cuda12_aarch64 = prev.callPackage ../pkgs/tensorrt/generic.nix {
      version = "10.8.0.43";
      cudaVersion = "12.8";
      arch = "aarch64-gnu";
      sha256 = "b01e5dd2c7c643252119d03d92eea97023418e92f45a3be0d0896e962923e43a";
    };

    tensorrt_8_6_cuda11 = prev.callPackage ../pkgs/tensorrt/generic.nix {
      version = "8.6.1.6";
      cudaVersion = "11.8";
      arch = "x86_64-gnu";
      sha256 = "e17e363bc1b738925ec9ad7e92c4cd52408acfa908811154803609d825ba2a35";
    };

    tensorrt_8_6_cuda12 = prev.callPackage ../pkgs/tensorrt/generic.nix {
      version = "8.6.1.6";
      cudaVersion = "12.0";
      arch = "x86_64-gnu";
      sha256 = "506142487f94b6cad6f13953e59bb9b7cd9b2e1bfbb01f99498cbedf2a6ce0a7";
    };

    tensorrt_8_6_cuda12_aarch64 = prev.callPackage ../pkgs/tensorrt/generic.nix {
      version = "8.6.1.6";
      cudaVersion = "12.0";
      arch = "aarch64-gnu";
      sha256 = "ee81c6aa98cb7157a0479b9034c6dcf22f4e220a5b032eaf62aab8d048719dd2";
    };
  };
}
