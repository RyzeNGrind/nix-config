# TensorRT package based on NVIDIA's distribution model
{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, cudaPackages
}:

let
  # TensorRT version manifests
  manifests = {
    "10.8.0.43" = {
      x86_64-linux = {
        "11.8" = {
          url = "file:///home/${builtins.getEnv "USER"}/.tensorrt/TensorRT-10.8.0.43.Linux.x86_64-gnu.cuda-11.8.tar.gz";
          sha256 = "661749f5951a9ce490dd36ca34422f4be7c72d0f935d9f9276b50be1488447e9";
        };
        "12.8" = {
          url = "file:///home/${builtins.getEnv "USER"}/.tensorrt/TensorRT-10.8.0.43.Linux.x86_64-gnu.cuda-12.8.tar.gz";
          sha256 = "577d6d8af538153414b9867c666b4f65852fc2eb1e7c0ea3a206e5fafbc7d49e";
        };
      };
      aarch64-linux = {
        "12.8" = {
          url = "file:///home/${builtins.getEnv "USER"}/.tensorrt/TensorRT-10.8.0.43.Linux.aarch64-gnu.cuda-12.8.tar.gz";
          sha256 = "b01e5dd2c7c643252119d03d92eea97023418e92f45a3be0d0896e962923e43a";
        };
      };
    };
    "8.6.1.6" = {
      x86_64-linux = {
        "11.8" = {
          url = "file:///home/${builtins.getEnv "USER"}/.tensorrt/TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-11.8.tar.gz";
          sha256 = "e17e363bc1b738925ec9ad7e92c4cd52408acfa908811154803609d825ba2a35";
        };
        "12.0" = {
          url = "file:///home/${builtins.getEnv "USER"}/.tensorrt/TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-12.0.tar.gz";
          sha256 = "506142487f94b6cad6f13953e59bb9b7cd9b2e1bfbb01f99498cbedf2a6ce0a7";
        };
      };
      aarch64-linux = {
        "12.0" = {
          url = "file:///home/${builtins.getEnv "USER"}/.tensorrt/TensorRT-8.6.1.6.Ubuntu-20.04.aarch64-gnu.cuda-12.0.tar.gz";
          sha256 = "ee81c6aa98cb7157a0479b9034c6dcf22f4e220a5b032eaf62aab8d048719dd2";
        };
      };
    };
  };

  # Helper function to create a TensorRT derivation
  mkTensorRT = version: cudaVersion: manifest:
    stdenv.mkDerivation {
      pname = "tensorrt";
      inherit version;

      src = fetchurl {
        url = manifest.url;
        inherit (manifest) sha256;
      };

      nativeBuildInputs = [ autoPatchelfHook ];

      buildInputs = with cudaPackages; [
        cuda_cudart
        cuda_cupti
        libcublas
        cudnn
      ];

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        mkdir -p $out/{lib64,include,bin}
        cp -r include/* $out/include/
        cp -r lib/* $out/lib64/
        cp -r bin/* $out/bin/

        # Create compatibility symlinks
        ln -s $out/lib64 $out/lib

        runHook postInstall
      '';

      preFixup = ''
        addAutoPatchelfSearchPath $out/lib64
      '';

      meta = with lib; {
        description = "NVIDIA TensorRT ${version} for CUDA ${cudaVersion}";
        homepage = "https://developer.nvidia.com/tensorrt";
        license = licenses.unfree;
        platforms = [ stdenv.hostPlatform.system ];
        maintainers = with maintainers; [ ryzengrind ];
      };
    };

  # Get the appropriate manifest for the current system
  currentManifest = 
    if builtins.hasAttr stdenv.hostPlatform.system manifests."10.8.0.43"
    then manifests."10.8.0.43".${stdenv.hostPlatform.system}."12.8"
    else null;

in
if currentManifest != null
then mkTensorRT "10.8.0.43" "12.8" currentManifest
else throw "TensorRT is not supported on ${stdenv.hostPlatform.system}" 