# 3. WSL Configuration Testing Strategy

Date: 2024-02-12

## Status

Accepted

## Context

When developing NixOS configurations for WSL environments, we need a robust testing strategy to
ensure system stability and prevent configuration issues. This is particularly important given the
unique challenges of running NixOS under WSL.

## Decision

We have implemented a multi-stage testing approach:

1. Pre-commit hooks for code quality:

- Alejandra for Nix formatting
- Deadnix for dead code detection
- Prettier for general formatting
- Statix for static analysis

2. System configuration testing:

```nix
nix --extra-experimental-features "nix-command flakes" run nixpkgs#nixos-rebuild -- test --flake .#nix-pc
```

3. Flake integrity checking:

```nix
nix flake check --all-systems
```

4. Derivation path validation:

```nix
nix eval .#nixosConfigurations.nix-pc.config.system.build.toplevel.drvPath
```

5. Post-Switch Verification:

```bash
# Check if flake configuration is active
readlink -f /run/current-system

# Verify system version and configuration
nixos-version
systemctl status

# Test WSL integration
wslpath -w /
wslvar USERPROFILE

# Verify user and permissions
id ryzengrind
groups ryzengrind

# Check critical services
systemctl status dbus
systemctl status docker

# Verify Home Manager
home-manager generations
nix profile history --profile /nix/var/nix/profiles/per-user/ryzengrind/home-manager

# Test development environment
docker info
code --version
git --version

# Check system resources
free -h
df -h
```

## Verification Checklist

### System State

- [ ] Current system path matches expected flake output
- [ ] NixOS version matches flake configuration
- [ ] System services are running correctly
- [ ] No critical errors in systemd journal

### User Environment

- [ ] User has correct permissions and groups
- [ ] Home Manager profile is active
- [ ] Development tools are accessible
- [ ] Git hooks are working

### WSL Integration

- [ ] WSL path mapping works correctly
- [ ] Windows interop functions properly
- [ ] Docker integration is active
- [ ] System resources are properly allocated

### Development Environment

- [ ] Pre-commit hooks are installed and working
- [ ] Development shell activates correctly
- [ ] Required tools are in PATH
- [ ] Build environment is properly configured

### Recovery Readiness

- [ ] Previous generation is available for rollback
- [ ] System can be rebuilt from flake
- [ ] Emergency recovery procedures are documented
- [ ] Backup paths are accessible

## Configuration Decisions

1. Enabled dirty tree warnings during development:

```nix
warn-dirty = true;
```

2. Enabled key experimental features:

- nix-command
- flakes
- repl-flake
- recursive-nix
- dynamic-derivations
- cgroups
- ca-derivations

3. Optimized build settings:

- auto-optimise-store = true
- keep-outputs = true
- keep-derivations = true
- max-jobs = "auto"

## Safety and Rollback Procedures

### Pre-Switch Safety Checklist

1. Verify all tests pass:

   - Pre-commit hooks
   - System configuration build
   - Flake integrity
   - Derivation validation

2. Ensure critical services are configured:
   - WSL integration
   - User sessions
   - System services
   - Home Manager

### Rollback Procedure

If issues occur after switching to the new configuration:

1. Immediate rollback:

   ```bash
   sudo nixos-rebuild switch --rollback
   ```

2. Specific generation rollback:

   ```bash
   # List available generations
   sudo nix-env -p /nix/var/nix/profiles/system --list-generations

   # Roll back to a specific generation
   sudo nixos-rebuild switch --to-generation <number>
   ```

3. Emergency WSL Recovery:
   - Exit current WSL session
   - From Windows PowerShell:
     ```powershell
     wsl --terminate NixOS
     wsl --start NixOS
     ```

## Consequences

### Positive

- Consistent code quality through automated checks
- Early detection of configuration issues
- Improved build performance
- Better development experience with reduced warnings
- Reproducible builds across different environments
- Safe rollback options available

### Negative

- Additional setup complexity
- Slightly longer initial build times due to comprehensive checks
- Need to maintain testing infrastructure
- Each configuration switch requires full testing cycle

## References

- [NixOS WSL Documentation](https://github.com/nix-community/NixOS-WSL)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [NixOS Rollback Guide](https://nixos.wiki/wiki/NixOS#Rollback)
- Previous ADRs:
  - [001-profile-based-configuration.md](./001-profile-based-configuration.md)
  - [002-multi-architecture-cache.md](./002-multi-architecture-cache.md)
