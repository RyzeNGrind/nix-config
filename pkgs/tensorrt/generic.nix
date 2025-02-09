# Generic TensorRT package builder
{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, cudaPackages
, version
, cudaVersion
, arch
, sha256
}:

let
  # Special case for TensorRT 8.6.1.6 aarch64
  filename = if version == "8.6.1.6" && arch == "aarch64-gnu"
    then "TensorRT-${version}.Ubuntu-20.04.${arch}.cuda-${cudaVersion}.tar.gz"
    else "TensorRT-${version}.Linux.${arch}.cuda-${cudaVersion}.tar.gz";
in
stdenv.mkDerivation {
  pname = "tensorrt";
  inherit version;

  src = fetchurl {
    url = "file:///home/${builtins.getEnv "USER"}/.tensorrt/${filename}";
    inherit sha256;
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
} 