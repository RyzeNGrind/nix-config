# 1. Profile-Based Configuration Architecture

Date: 2024-02-10

## Status

Accepted

## Context

The NixOS configuration needed to be restructured to support multiple use cases (development, gaming, server) while maintaining:
- Clear separation of concerns
- Easy composition of features
- Testability
- Maintainability
- Version control integration

## Decision

We will implement a profile-based configuration architecture with the following characteristics:

1. Base Profile
   - Core system settings
   - Security configurations
   - System optimization
   - Common utilities

2. Specialized Profiles
   - Development environment
   - Gaming setup
   - Server configuration
   - Each profile is self-contained and composable

3. Feature Flags System
   - Conditional module loading
   - Version tagging based on enabled features
   - Feature state tracking in flake.lock

4. Testing Framework
   - Unit tests for each profile
   - Integration tests for profile combinations
   - Automated testing via GitHub Actions
   - VM-based testing for system configurations

5. Module Organization
   ```
   /profiles
     /base         # Base profile all others inherit from
     /gaming       # Gaming-specific configurations
     /dev          # Development environment
     /server       # Server configurations
   
   /modules
     /core         # Core system components
       network.nix
       security.nix
       users.nix
     /services     # Service-specific modules
       virtualization.nix
       containers.nix
     /hardware     # Hardware-specific configurations
       nvidia.nix
       amd.nix
   ```

## Consequences

### Positive

1. **Modularity**
   - Easy to add/remove features
   - Clear dependencies
   - Isolated testing

2. **Maintainability**
   - Self-documenting structure
   - Standardized testing
   - Version-controlled feature flags

3. **Flexibility**
   - Compose profiles as needed
   - Feature toggles for different environments
   - Hardware-specific optimizations

4. **Testing**
   - Automated test suite
   - Profile-specific tests
   - Integration testing
   - CI/CD integration

### Negative

1. **Complexity**
   - More files to manage
   - Need for documentation
   - Learning curve for new contributors

2. **Build Time**
   - More tests to run
   - Larger CI/CD pipeline
   - Multiple profile combinations to test

3. **Resource Usage**
   - VM tests require more resources
   - Multiple test environments

## Mitigation Strategies

1. **Documentation**
   - Comprehensive README files
   - Architecture Decision Records
   - Example configurations
   - Clear naming conventions

2. **Testing Optimization**
   - Parallel test execution
   - Test caching
   - Selective testing based on changes
   - CI/CD matrix builds

3. **Development Workflow**
   - Pre-commit hooks
   - Automated linting
   - Documentation templates
   - Contribution guidelines

## References

1. NixOS Module System
   - [NixOS Manual: Writing NixOS Modules](https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules)
   - [NixOS Wiki: NixOS Tests](https://nixos.wiki/wiki/NixOS_Tests)

2. Feature Flags
   - [Feature Toggles (aka Feature Flags)](https://martinfowler.com/articles/feature-toggles.html)
   - [NixOS RFC: Flake Feature Flags](https://github.com/NixOS/rfcs/pull/89)