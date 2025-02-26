# 4. Comprehensive Testing Strategy

Date: 2024-03-12

## Status

Accepted

## Context

Building upon [ADR 003 - WSL Configuration Testing](./003-wsl-configuration-testing.md), we need a
more comprehensive testing strategy that covers not just WSL-specific aspects but all components of
our NixOS configuration. This includes flake integrity, home-manager configurations, and system-wide
tests.

## Decision

We have implemented a comprehensive testing command that extends the WSL testing strategy:

```bash
RUN_SYSTEM_TEST=1 RUN_HOME_TEST=1 ./scripts/test-flake.sh
```

### Test Components

1. **WSL-Specific Tests** (from ADR 003)

   - WSL integration checks
   - User environment verification
   - Service status validation

2. **Pre-commit Hooks**

   ```bash
   # Individual formatters and linters
   alejandra  # Nix formatting
   deadnix    # Dead code detection
   prettier   # General formatting
   statix     # Static analysis
   ```

3. **Flake Checks**

   ```nix
   nix flake check \
     --no-build \
     --keep-going \
     --show-trace \
     --allow-import-from-derivation
   ```

4. **Configuration Tests**

   ```nix
   # Test individual configurations
   nix eval --json .#nixosConfigurations.nix-pc.config.system.build.toplevel.drvPath
   nix eval --json .#nixosConfigurations.nix-ws.config.system.build.toplevel.drvPath
   nix eval --json .#homeConfigurations."ryzengrind@nix-pc".activationPackage.drvPath
   ```

5. **System Build Test** (when RUN_SYSTEM_TEST=1)

   ```bash
   sudo nixos-rebuild test \
     --flake .#nix-pc \
     --show-trace \
     --keep-going
   ```

6. **Home Manager Test** (when RUN_HOME_TEST=1)
   ```bash
   home-manager switch --flake .#ryzengrind@nix-pc
   ```

### Test Environment

The test script runs in a development shell with:

- All necessary formatting tools
- Git and pre-commit hooks
- Nix development tools
- Home Manager

### Error Handling

The script includes:

- Status checking for each test phase
- Warning-level failures for non-critical issues
- Critical failure detection for system-breaking issues
- Proper exit code propagation

### Common Issues and Solutions

1. **Fish Shell Configuration**

   ```nix
   # Required in configuration.nix
   programs.fish.enable = true;
   ```

2. **Git Tree State**

   ```bash
   # Clean working directory before testing
   git add .
   git commit -m "WIP: Testing configuration"
   ```

3. **WSL-Specific Checks**
   ```bash
   # Verify WSL integration
   wslpath -w /
   wslvar USERPROFILE
   ```

## Consequences

### Positive

- Comprehensive testing coverage
- Early detection of configuration issues
- Consistent code quality
- Clear feedback on test results
- Reproducible test environment

### Negative

- Longer test execution time
- Resource intensive
- Requires root access for system tests
- May require WSL-specific workarounds

## Implementation Notes

1. **Test Script Location**: `scripts/test-flake.sh`
2. **Required Permissions**: sudo access for system tests
3. **Environment Variables**:
   - `RUN_SYSTEM_TEST=1`: Enable full system testing
   - `RUN_HOME_TEST=1`: Enable Home Manager testing

## References

- [NixOS Testing Guide](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)
- [Home Manager Testing](https://nix-community.github.io/home-manager/index.html#ch-testing)
- Previous ADRs:
  - [001-profile-based-configuration.md](./001-profile-based-configuration.md)
  - [002-multi-architecture-cache.md](./002-multi-architecture-cache.md)
  - [003-wsl-configuration-testing.md](./003-wsl-configuration-testing.md)
