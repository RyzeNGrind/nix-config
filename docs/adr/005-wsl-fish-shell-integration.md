# 5. WSL Fish Shell Integration

Date: 2024-02-24

## Status

Accepted

## Context

We needed to ensure proper integration of the Fish shell within our NixOS WSL environment, particularly focusing on:
- Correct path handling and environment variables
- Integration with development tools (starship, zoxide, direnv)
- VSCode terminal integration
- System-level and user-level shell configuration

## Decision

We have implemented a comprehensive Fish shell integration strategy that includes:

1. System-level configuration:
   - Core utilities and paths setup
   - Vendor completions and functions
   - Nix environment integration
   - Shell tool initialization

2. User-level configuration:
   - Custom shell initialization
   - Tool-specific configurations
   - Path and environment variable management
   - Modern command-line tool aliases

3. VSCode integration:
   - Proper shell path configuration
   - Environment variable setup
   - WSL-specific terminal profile

## Consequences

### Positive

- Consistent shell environment across system and user levels
- Proper integration with Nix ecosystem
- Improved development experience in VSCode
- Better handling of command-line tools and utilities
- Clear separation between system and user configurations

### Negative

- Additional complexity in configuration management
- Need to maintain both system and user-level shell configurations
- Potential for path-related issues if not properly maintained

## Implementation Notes

1. System Configuration:
   ```nix
   programs.fish = {
     enable = true;
     vendor = {
       completions.enable = true;
       config.enable = true;
       functions.enable = true;
     };
   };
   ```

2. User Configuration:
   ```nix
   programs.fish = {
     enable = true;
     interactiveShellInit = ''
       # Environment setup
       set -gx NIX_PATH ...
       set -gx NIX_PROFILES ...
       
       # Tool initialization
       starship init fish | source
       zoxide init fish | source
       direnv hook fish | source
     '';
   };
   ```

3. VSCode Settings:
   ```json
   {
     "terminal.integrated.profiles.windows": {
       "NixOS (WSL)": {
         "path": ["${env:windir}\\System32\\wsl.exe"],
         "args": ["-d", "NixOS", "--exec", "/run/current-system/sw/bin/fish"]
       }
     }
   }
   ```

## References

- [Fish Shell Documentation](https://fishshell.com/docs/current/index.html)
- [NixOS Fish Module Documentation](https://nixos.org/manual/nixos/stable/options.html#opt-programs.fish.enable)
- [VSCode WSL Integration](https://code.visualstudio.com/docs/remote/wsl)
- [Nix Profiles Documentation](https://nixos.org/manual/nix/stable/command-ref/nix-profile.html) 