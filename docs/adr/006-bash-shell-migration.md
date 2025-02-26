# 6. Migration from Fish to Bash Shell

Date: 2024-02-25

## Status

Accepted

## Context

The initial configuration used Fish shell as the default shell for both user and system environments. While Fish offers modern features and user-friendly syntax, it introduced several challenges:

1. Compatibility issues with some WSL-specific features and scripts
2. Additional complexity in maintaining Fish-specific configurations
3. Potential issues with scripts that assume POSIX compliance
4. Need for simpler and more standardized shell environment

## Decision

We decided to migrate from Fish shell to Bash shell as the default shell for both user and system environments. This change includes:

1. Replacing Fish shell configurations with Bash equivalents
2. Updating system activation scripts to use Bash
3. Modifying shell-specific environment variables and paths
4. Implementing proper Bash completion and integration with tools

### Implementation Details

1. Shell Configuration:
   - Default shell set to `/bin/bash`
   - Bash completion enabled system-wide
   - Shell-specific paths and environment variables updated

2. Tool Integration:
   - Starship prompt configured for Bash
   - Direnv hooks added to Bash initialization
   - Zoxide integration for improved navigation
   - FZF for enhanced command-line fuzzy finding

3. Directory Structure:
   ```
   /etc/bash/
   └── bashrc.d/
       └── nix-daemon.bash
   ~/.bashrc.d/
   └── nix-develop.bash
   ```

4. Environment Variables:
   ```bash
   SHELL="/bin/bash"
   PATH="/nix/store/*/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/run/wrappers/bin:/usr/local/bin:/usr/bin:/bin"
   ```

## Consequences

### Positive

1. Better compatibility with WSL and system scripts
2. Simplified shell configuration management
3. Improved POSIX compliance
4. Reduced complexity in shell-specific configurations
5. More standardized environment across systems

### Negative

1. Loss of some Fish-specific features (syntax highlighting, autosuggestions)
2. Need to maintain separate branch for Fish shell users
3. Migration effort for existing users
4. Potential learning curve for users accustomed to Fish

### Neutral

1. Different workflow for shell customization
2. Changed environment setup process
3. Alternative approach to shell completion

## Migration Path

1. Create new branch for Bash migration
2. Update all shell-specific configurations
3. Test WSL compatibility
4. Document changes and migration steps
5. Tag working version
6. Maintain separate branch for Fish shell

## References

- [Bash Documentation](https://www.gnu.org/software/bash/manual/bash.html)
- [NixOS Wiki - Bash](https://nixos.wiki/wiki/Bash)
- [WSL Documentation](https://learn.microsoft.com/en-us/windows/wsl/) 