# 3. Incremental Module Activation Strategy

Date: 2024-02-10

## Status

Accepted

## Context

The current configuration enables multiple modules by default, making it difficult to:

- Test individual components
- Debug issues
- Ensure module independence
- Validate functionality

## Decision

We will implement an incremental module activation strategy:

1. Core Components

   - WSL module remains enabled (currently working)
   - All other modules disabled by default
   - Feature flags for explicit activation

2. Testing Strategy

   - Individual module testing
   - Integration testing via CI
   - Automated validation
   - Dependency tracking

3. Module Dependencies

   ```nix
   {
     config.modules = {
       wsl.enable = true;  # Only WSL enabled by default

       # Disabled by default, require explicit activation
       cache.enable = false;
       dev.enable = false;
       gaming.enable = false;
       server.enable = false;
     };
   }
   ```

4. CI Pipeline
   - Merge test.yml and nix-ci.yml
   - Focus on module-specific tests
   - Matrix testing for enabled modules
   - Cache validation

## Implementation

1. Module System

   ```nix
   {
     options.modules = {
       # Core modules (enabled)
       wsl = {
         enable = lib.mkEnableOption "WSL support";
         gui.enable = lib.mkEnableOption "GUI support";
         cuda.enable = lib.mkEnableOption "CUDA support";
       };

       # Optional modules (disabled)
       cache = {
         enable = lib.mkOption {
           type = lib.types.bool;
           default = false;
           description = "Enable cache system";
         };
       };

       # Other modules follow same pattern
     };
   }
   ```

2. Testing Framework
   ```nix
   {
     test.modules = {
       wsl = {
         enable = true;
         tests = ["basic" "gui" "cuda"];
       };
       cache = {
         enable = false;
         tests = ["s3" "seaweed" "local"];
       };
     };
   }
   ```

## Consequences

### Positive

1. **Clarity**

   - Clear module status
   - Explicit dependencies
   - Controlled testing
   - Better debugging

2. **Reliability**

   - Isolated testing
   - Verified functionality
   - Reduced complexity
   - Stable base system

3. **Maintainability**
   - Easier updates
   - Clear documentation
   - Simple troubleshooting
   - Version control

### Negative

1. **Initial Setup**

   - Manual module activation
   - More configuration
   - Additional testing
   - Documentation needs

2. **Development Flow**
   - Slower feature rollout
   - More test cycles
   - Increased CI time
   - Complex matrices

## Mitigation Strategies

1. **Documentation**

   - Clear activation guides
   - Test documentation
   - Troubleshooting steps
   - Example configurations

2. **Testing**

   - Automated test suites
   - Integration tests
   - Dependency checks
   - CI optimization

3. **Development**
   - Feature templates
   - Module guidelines
   - Review process
   - Version tracking

## References

1. Module System

   - [NixOS Module System](https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules)
   - [Flakes Feature Flags](https://nixos.wiki/wiki/Flakes#Feature_Flags)

2. Testing
   - [NixOS Testing Framework](https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests)
   - [GitHub Actions Matrix Testing](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
