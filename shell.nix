{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.nixpkgs-fmt
    pkgs.nix-linter
  ];

  shellHook = ''
    echo "nixpkgs-fmt and nix-linter are now available."
    echo "Use 'nixpkgs-fmt <file or directory>' to format Nix code."
    echo "Use 'nix-linter <file>' to lint Nix code."
  '';
}
