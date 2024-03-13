{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.deadnix
    pkgs.statix
    pkgs.nixpkgs-fmt
    pkgs.nixpkgs-lint
  ];

  shellHook = ''
    echo -e "\e[1;34mnixpkgs-fmt, deadnix, statix, and nixpkgs-lint are now available in this shell.\e[0m"
    echo -e "\e[1;34mUse 'nixpkgs-fmt <file or directory>' to format Nix code.\e[0m"
    echo -e "\e[1;34mUse 'statix check <file or directory>' to lint Nix code with statix.\e[0m"
    echo -e "\e[1;34mUse 'deadnix <file or directory>' to remove unused variables in Nix code.\e[0m"
    echo -e "\e[1;34mUse 'nixpkgs-lint <file or directory>' for additional linting of Nixpkgs specifics.\e[0m"
  '';
}
