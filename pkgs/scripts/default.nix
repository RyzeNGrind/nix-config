# Script management module
{ pkgs }:

let
  # Helper function to create script packages
  mkScript = name: path: pkgs.writeScriptBin name (builtins.readFile path);
  
  # Root directory of the project relative to this file
  projectRoot = ../../.;
in
{
  # ML environment setup script
  mlEnvSetup = mkScript "ml-env-setup" (projectRoot + "/scripts/env-setup/ml-env.sh");

  # VSCodium cursor server script
  vscodiumCursorServer = mkScript "vscodium-cursor-server" (projectRoot + "/scripts/env-setup/vscodium-cursor-server.sh");

  # Pre-commit hook script
  preCommitHook = mkScript "pre-commit-hook" (projectRoot + "/scripts/shell-hooks/pre-commit.sh");
} 