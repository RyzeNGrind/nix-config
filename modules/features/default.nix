# Feature modules following ADR-003 incremental activation strategy
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./hyprland
    ./cuda
    ./shell
    ./development
  ];

  options.features = {
    enable = mkEnableOption "Enable feature system";

    hyprland.enable = mkEnableOption "Hyprland desktop environment";
    cuda.enable = mkEnableOption "CUDA development support";
    shell.enable = mkEnableOption "Enhanced shell environment";
    development.enable = mkEnableOption "Development tools";
  };

  config = mkIf config.features.enable {
    assertions = [
      {
        assertion = config.features.cuda.enable -> config.nixpkgs.config.allowUnfree;
        message = "CUDA support requires allowUnfree to be enabled";
      }
    ];

    warnings =
      optional (config.features.cuda.enable && !config.hardware.nvidia.package)
      "CUDA is enabled but no NVIDIA driver package is specified";
  };
}
