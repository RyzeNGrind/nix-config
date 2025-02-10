# 4. specialisation-Based Configuration Management

Date: 2024-02-10

## Status

Accepted

## Context

Need to support multiple machine configurations while:

- Maintaining a single source of truth
- Supporting both WSL and native NixOS
- Enabling easy testing and rollback
- Leveraging `nixos-rebuild --specialisation`

## Decision

We will implement a specialisation-based configuration structure:

1. Base Configurations

   ```nix
   {
     # Base WSL configuration
     baseWslConfig = {
       # Common WSL settings
       wsl.enable = true;
       wsl.nativeSystemd = true;
     };

     # Base desktop configuration
     baseDesktopConfig = {
       # Common desktop settings
       services.xserver.enable = true;
     };
   }
   ```

2. Machine specialisations

   ```nix
   {
     specialisation = {
       # daimyo00 (WSL)
       daimyo00-wsl = {
         inheritParentConfig = true;
         configuration = {
           wsl.gui.enable = true;
           wsl.cuda.enable = false;
         };
       };

       # daimyo (Desktop)
       daimyo-desktop = {
         inheritParentConfig = true;
         configuration = {
           hardware.nvidia.enable = true;
           services.xserver.videoDrivers = ["nvidia"];
         };
       };

       # SB3 (WSL)
       sb3-wsl = {
         inheritParentConfig = true;
         configuration = {
           wsl.gui.enable = true;
           wsl.cuda.enable = true;
         };
       };
     };
   }
   ```

3. Testing Strategy
   ```nix
   {
     test.specialisation = {
       # Test each specialisation
       testScript = ''
         machine.succeed("nixos-rebuild test --specialisation daimyo00-wsl")
         machine.succeed("nixos-rebuild test --specialisation daimyo-desktop")
         machine.succeed("nixos-rebuild test --specialisation sb3-wsl")
       '';
     };
   }
   ```

## Implementation

1. Directory Structure

   ```
   /hosts
     /base
       wsl.nix      # Base WSL configuration
       desktop.nix  # Base desktop configuration
     /daimyo00
       default.nix  # WSL-specific config
     /daimyo
       default.nix  # Desktop-specific config
     /sb3
       default.nix  # WSL-specific config
   ```

2. Configuration Inheritance

   ```nix
   { config, lib, pkgs, ... }:
   {
     imports = [
       ../base/wsl.nix  # or desktop.nix
     ];

     specialisation = {
       # Machine-specific specialisations
     };
   }
   ```

3. Recovery Strategy

   ```bash
   # Test specialisation
   nixos-rebuild test --specialisation daimyo00-wsl

   # Switch to specialisation
   nixos-rebuild switch --specialisation daimyo00-wsl

   # Rollback if needed
   nixos-rebuild switch --rollback
   ```

## Consequences

### Positive

1. **Flexibility**

   - Easy switching between configurations
   - Simple testing process
   - Clear inheritance chain
   - Isolated changes

2. **Maintainability**

   - Single source of truth
   - Shared base configurations
   - Clear specialisation boundaries
   - Easy rollbacks

3. **Testing**
   - specialisation-specific tests
   - Safe configuration testing
   - Quick rollbacks
   - Isolated environments

### Negative

1. **Complexity**

   - More configuration files
   - Additional testing needed
   - Learning curve
   - Documentation overhead

2. **Resource Usage**
   - Multiple configurations
   - Test environments
   - Build artifacts
   - Cache storage

## Mitigation Strategies

1. **Documentation**

   - Clear usage guides
   - Example configurations
   - Testing procedures
   - Recovery steps

2. **Testing**

   - Automated test suite
   - Pre-switch validation
   - Post-switch verification
   - Rollback testing

3. **Development**
   - Feature templates
   - Base configurations
   - Shared modules
   - Version control

## References

1. NixOS Documentation

   - [NixOS Manual: Specialisation](https://nixos.org/manual/nixos/stable/index.html#sec-specialisation)
   - [NixOS Wiki: Configuration Collection](https://nixos.wiki/wiki/Configuration_Collection)

2. Community Resources
   - [Reddit: How to restore last working config](https://www.reddit.com/r/NixOS/comments/1amj6qm/how_to_restore_last_working_config/)
   - [NixOS Discourse: Configuration Management](https://discourse.nixos.org/t/configuration-management-tips/5442)
