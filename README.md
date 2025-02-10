# NixOS Configuration

A modular, composable, and tested NixOS configuration using profiles and feature flags.

## Features

- Profile-based configuration
- Automated testing
- Feature flag system
- WSL support
- Development environments
- Gaming optimizations
- Server configurations

## Structure

```
.
├── docs/
│   └── adr/                    # Architecture Decision Records
├── modules/
│   ├── core/                   # Core system components
│   │   ├── network.nix
│   │   └── security.nix
│   ├── services/               # Service configurations
│   │   ├── wsl.nix
│   │   └── containers.nix
│   └── hardware/               # Hardware-specific settings
│       ├── nvidia.nix
│       └── amd.nix
├── profiles/                   # System profiles
│   ├── base/                   # Base system configuration
│   ├── dev/                    # Development environment
│   ├── gaming/                 # Gaming optimizations
│   └── server/                 # Server configurations
└── tests/                      # System tests
```

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/nix-config.git
   cd nix-config
   ```

2. Enable the profiles you need in your `configuration.nix`:
   ```nix
   {
     profiles = {
       base.enable = true;
       dev.enable = true;  # For development
       gaming.enable = true;  # For gaming
     };
   }
   ```

3. Apply the configuration:
   ```bash
   sudo nixos-rebuild switch --flake .#
   ```

## Profiles

### Base Profile
- Core system settings
- Security configurations
- System optimization
- Common utilities

### Development Profile
- Programming languages
- Development tools
- Container support
- WSL integration

### Gaming Profile
- Steam support
- Wine configuration
- GPU optimization
- Game streaming

### Server Profile
- Service configurations
- Container orchestration
- Monitoring setup
- Backup solutions

## Feature Flags

Enable features using the feature flag system:

```nix
{
  features = {
    nvidia.enable = true;
    wsl = {
      enable = true;
      gui.enable = true;
    };
    dev = {
      python.enable = true;
      rust.enable = true;
    };
  };
}
```

## Testing

Run the test suite:

```bash
# Run all tests
nix build .#nixosTests.all

# Test specific profile
nix build .#nixosTests.dev

# Test WSL configuration
nix build .#nixosTests.wsl
```

## Development

1. Install pre-commit hooks:
   ```bash
   nix develop
   pre-commit install
   ```

2. Make changes and commit:
   - Changes are automatically formatted
   - Tests run on commit
   - Documentation is verified

3. Submit a pull request:
   - CI runs all tests
   - Code is reviewed
   - Changes are merged

## WSL Support

Special support for Windows Subsystem for Linux:

1. Enable WSL features:
   ```nix
   {
     features.wsl = {
       enable = true;
       gui.enable = true;  # For GUI applications
       cuda.enable = true;  # For NVIDIA support
     };
   }
   ```

2. Install in WSL:
   ```bash
   wsl --import NixOS ./nixos nixos.tar.gz --version 2
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Best Practices

1. Always enable the base profile
2. Test changes locally before pushing
3. Update documentation
4. Follow the coding style
5. Write tests for new features

## Troubleshooting

Common issues and solutions:

1. **Build failures**
   - Check the error message
   - Verify dependencies
   - Review recent changes

2. **Test failures**
   - Run tests locally
   - Check test logs
   - Verify test environment

## License

MIT - See LICENSE file for details

## Acknowledgments

- NixOS community
- Contributors
- Testing frameworks
- Documentation tools
