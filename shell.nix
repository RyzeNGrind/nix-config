{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.deadnix
    pkgs.statix
    pkgs.nixpkgs-fmt
    pkgs.nixpkgs-lint
  ];

  shellHook = ''
    echo "nixpkgs-fmt, deadnix, statix, and nixpkgs-lint are now available in this shell."
    echo "Use 'nixpkgs-fmt <file or directory>' to format Nix code."
    echo "Use 'statix check <file or directory>' to lint Nix code with statix."
    echo "Use 'deadnix <file or directory>' to remove unused variables in Nix code."
    echo "Use 'nixpkgs-lint <file or directory>' for additional linting of Nixpkgs specifics."
  '';
}
