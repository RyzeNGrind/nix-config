# 5. Proper Flake Module Usage

Date: 2024-02-17

## Status

Accepted

## Context

Previous ADRs established a profile-based configuration architecture and specialisation strategy, but did not fully leverage NixOS flake module system capabilities. This led to:

- Unnecessary abstraction layers
- Suboptimal module composition
- Unclear module boundaries
- Potential performance impact

## Decision

We will implement proper flake module usage following these principles:

1. Direct Input Module Usage

   ```nix
   # In flake.nix
   inputs = {
     nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
     home-manager.url = "github:nix-community/home-manager";
   };

   outputs = { self, nixpkgs, home-manager, ... } @ inputs:
     let
       mkHost = { name, modules ? [], ... }:
         nixpkgs.lib.nixosSystem {
           modules = [
             # Direct use of input modules
             home-manager.nixosModules.home-manager
             # Local modules
             ./modules/core.nix
           ] ++ modules;
         };
     in { ... };
   ```

2. Module Organization

   ```
   /modules
     core.nix           # Core system configuration
     /features          # Feature-specific modules
     /profiles          # Profile-specific modules
     /specialisations   # Specialisation configurations
   ```

3. Module Composition

   ```nix
   # In host configuration
   { config, pkgs, ... }:
   {
     imports = [
       ../modules/core.nix
       ../modules/features/desktop.nix
       ../modules/profiles/development.nix
     ];
   }
   ```

## Consequences

### Positive

1. **Performance**

   - Direct module imports
   - Reduced abstraction overhead
   - Efficient evaluation

2. **Maintainability**

   - Clear module boundaries
   - Standard NixOS patterns
   - Simplified debugging

3. **Compatibility**
   - Better upstream integration
   - Standard module interface
   - Future-proof design

### Negative

1. **Migration Effort**
   - Update existing configurations
   - Retrain developers
   - Documentation updates

## Mitigation Strategies

1. **Documentation**

   - Clear migration guide
   - Updated examples
   - Best practices

2. **Testing**
   - Comprehensive test suite
   - Performance benchmarks
   - Compatibility checks

## References

1. [Nix Flakes](https://nixos.wiki/wiki/Flakes)
2. [NixOS Module System](https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules)
3. [Home Manager](https://nix-community.github.io/home-manager/)
