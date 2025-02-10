# NixOS Configuration

A modular, composable, and tested NixOS configuration using specialisations and feature flags.

## Features

- Single base configuration with specialisations
- WSL support with and without CUDA
- Baremetal configuration support
- Automated testing
- Feature flag system
- Development environments
- Gaming optimizations
- Server configurations

## Structure

```
.
├── docs/
│   └── adr/                    # Architecture Decision Records
├── hosts/
│   ├── base/                   # Base configurations
│   │   ├── default.nix         # Common settings
│   │   └── wsl.nix            # WSL-specific base
│   └── daimyo/                # Machine-specific config
│       ├── default.nix         # Base configuration
│       └── home.nix           # Home-manager config
├── modules/
│   ├── core/                   # Core system components
│   ├── services/               # Service configurations
│   └── hardware/               # Hardware-specific settings
└── tests/                      # System tests
```

## Quick Start

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/nix-config.git
   cd nix-config
   ```

2. Choose your configuration:

   ```bash
   # WSL with CUDA support
   sudo nixos-rebuild switch --flake .#daimyo --specialisation wsl-cuda

   # WSL without CUDA
   sudo nixos-rebuild switch --flake .#daimyo --specialisation wsl-nocuda

   # Baremetal configuration
   sudo nixos-rebuild switch --flake .#daimyo --specialisation baremetal
   ```

3. Test before switching:
   ```bash
   # Test a specialisation
   sudo nixos-rebuild test --flake .#daimyo --specialisation wsl-cuda
   ```

## Specialisations

### WSL with CUDA

```nix
{
  specialisation.wsl-cuda = {
    inheritParentConfig = true;
    configuration = {
      wsl.enable = true;
      wsl.cuda.enable = true;
    };
  };
}
```

### WSL without CUDA

```nix
{
  specialisation.wsl-nocuda = {
    inheritParentConfig = true;
    configuration = {
      wsl.enable = true;
      wsl.cuda.enable = false;
    };
  };
}
```

### Baremetal

```nix
{
  specialisation.baremetal = {
    inheritParentConfig = true;
    configuration = {
      wsl.enable = false;
      hardware.nvidia.enable = true;
    };
  };
}
```

## Testing

Run the test suite:

```bash
# Test all specialisations
nix build .#nixosTests.daimyo

# Test specific specialisation
nix build .#nixosTests.daimyo.wsl-cuda
nix build .#nixosTests.daimyo.wsl-nocuda
nix build .#nixosTests.daimyo.baremetal
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

## Best Practices

1. Start with base configuration
2. Use specialisations for variants
3. Test changes locally
4. Update documentation
5. Write tests for new features

## Troubleshooting

Common issues and solutions:

1. **Specialisation switch fails**

   - Check error messages
   - Test configuration first
   - Review recent changes
   - Use rollback if needed

2. **Test failures**
   - Run tests locally
   - Check test logs
   - Verify dependencies
   - Review changes

## License

MIT - See LICENSE file for details

## Acknowledgments

- NixOS community
- Contributors
- Testing frameworks
- Documentation tools
