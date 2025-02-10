# NixOS Configuration

A modular, composable, and tested NixOS configuration using profiles and feature flags.

## Features

- WSL support (enabled by default)
- Incremental module activation
- Automated testing
- Feature flag system
- Development environments (disabled by default)
- Gaming optimizations (disabled by default)
- Server configurations (disabled by default)

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
│   │   ├── wsl.nix            # WSL support (enabled)
│   │   └── containers.nix      # Container support (disabled)
│   └── hardware/               # Hardware-specific settings
│       ├── nvidia.nix          # NVIDIA support (disabled)
│       └── amd.nix            # AMD support (disabled)
├── profiles/                   # System profiles
│   ├── base/                   # Base system configuration
│   ├── dev/                    # Development environment (disabled)
│   ├── gaming/                 # Gaming optimizations (disabled)
│   └── server/                 # Server configurations (disabled)
└── tests/                      # System tests
```

## Quick Start

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/nix-config.git
   cd nix-config
   ```

2. Enable WSL support in your `configuration.nix`:

   ```nix
   {
     features.wsl = {
       enable = true;  # Enabled by default
       gui.enable = true;  # GUI support
       cuda.enable = false;  # CUDA support (optional)
     };
   }
   ```

3. Apply the configuration:
   ```bash
   sudo nixos-rebuild switch --flake .#
   ```

## Module Activation

Modules are disabled by default (except WSL) and can be enabled incrementally:

### Development Environment

```nix
{
  features.dev = {
    enable = true;  # Enable development environment
    python.enable = true;  # Python support
    rust.enable = true;  # Rust support
    go.enable = true;  # Go support
  };
}
```

### Gaming Support

```nix
{
  features.gaming = {
    enable = true;  # Enable gaming support
    steam.enable = true;  # Steam support
    wine.enable = true;  # Wine support
  };
}
```

### Hardware Support

```nix
{
  features = {
    nvidia = {
      enable = true;  # NVIDIA support
    };
    amd = {
      enable = true;  # AMD support
    };
  };
}
```

## Testing

Run the test suite:

```bash
# Test WSL configuration (enabled by default)
nix build .#nixosTests.wsl

# Test specific module (when enabled)
nix build .#nixosTests.dev  # Development environment
nix build .#nixosTests.gaming  # Gaming support
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

1. WSL features are enabled by default:

   ```nix
   {
     features.wsl = {
       enable = true;  # Already enabled by default
       gui.enable = true;  # For GUI applications
       cuda.enable = false;  # For NVIDIA support (optional)
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

1. Start with WSL configuration
2. Enable modules incrementally
3. Test changes locally
4. Update documentation
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
