#!/usr/bin/env bash

# Source nix-direnv if available
if [ -f ~/.nix-profile/share/nix-direnv/direnvrc ]; then
  source ~/.nix-profile/share/nix-direnv/direnvrc
fi

# Run pre-commit
exec pre-commit run --all-files 