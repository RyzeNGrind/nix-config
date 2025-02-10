# 4. Specialisation-Based Configuration Strategy

Date: 2024-02-10

## Status

Accepted

## Context

The current configuration structure has multiple separate NixOS configurations for different use cases (WSL with CUDA, WSL without CUDA, baremetal). This leads to:

- Code duplication
- Maintenance overhead
- Inconsistent configurations
- Difficulty in testing
- Complex deployment process

## Decision

We will implement a single NixOS configuration with specialisations for different use cases:

1. Base Configuration Structure

   ```nix
   nixosConfigurations.daimyo = {
     # Base configuration shared by all specialisations
     baseConfig = {
       # Common settings
     };

     # Specialisations
     specialisation = {
       wsl-cuda = {
         # WSL configuration with CUDA support
       };
       wsl-nocuda = {
         # WSL configuration without CUDA
       };
       baremetal = {
         # Baremetal configuration
       };
     };
   };
   ```

2. Activation Process

   ```bash
   # Activate WSL with CUDA
   nixos-rebuild switch --specialisation wsl-cuda

   # Activate WSL without CUDA
   nixos-rebuild switch --specialisation wsl-nocuda

   # Activate baremetal configuration
   nixos-rebuild switch --specialisation baremetal
   ```

3. Testing Strategy

   ```nix
   testing = {
     specialisation = {
       testScript = ''
         # Test base configuration
         machine.succeed("nixos-rebuild test")

         # Test specialisations
         machine.succeed("nixos-rebuild test --specialisation wsl-cuda")
         machine.succeed("nixos-rebuild test --specialisation wsl-nocuda")
         machine.succeed("nixos-rebuild test --specialisation baremetal")
       '';
     };
   };
   ```

## Consequences

### Positive

1. **Code Reuse**

   - Single base configuration
   - Shared components
   - DRY principle
   - Easier maintenance

2. **Consistency**

   - Unified configuration
   - Common base settings
   - Standardized structure
   - Version control

3. **Testing**

   - Simplified test suite
   - Common test framework
   - Comprehensive coverage
   - Automated validation

4. **Deployment**
   - Single entry point
   - Easy switching
   - Rollback support
   - Clear activation process

### Negative

1. **Complexity**

   - More complex base configuration
   - Careful feature management
   - Dependency handling
   - State management

2. **Testing Overhead**
   - Multiple configurations to test
   - Integration testing needed
   - Environment setup
   - CI pipeline complexity

## Mitigation Strategies

1. **Documentation**

   - Clear usage guides
   - Example configurations
   - Testing documentation
   - Troubleshooting steps

2. **Development Process**

   - Feature flags
   - Modular design
   - Clear interfaces
   - Version tracking

3. **Testing Framework**
   - Automated tests
   - Integration tests
   - Matrix testing
   - CI optimization

## References

1. NixOS Documentation

   - [NixOS Manual: Specialisation](https://nixos.org/manual/nixos/stable/index.html#sec-specialisation)
   - [NixOS Wiki: Configuration Collection](https://nixos.wiki/wiki/Configuration_Collection)

2. Testing
   - [NixOS Tests](https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests)
   - [GitHub Actions Matrix Testing](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
