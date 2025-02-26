# NixOS Configuration

A modular, composable, and tested NixOS configuration using profiles and feature flags.

## Features

- Profile-based configuration with fine-grained control
- Automated testing and validation
- Feature flag system for granular customization
- WSL support with GUI capabilities
- Development environments with IDE integration
- Gaming optimizations and Steam support
- Security and VPN configurations
- Desktop environment with modern UI/UX

## Structure

```
.
├── docs/
│   └── adr/                    # Architecture Decision Records
├── modules/
│   ├── core/                   # Core system components
│   │   ├── network.nix
│   │   └── security.nix
│   ├── nixos/
│   │   └── profiles/          # System profiles
│   │       ├── dev.nix        # Development environment
│   │       ├── desktop.nix    # Desktop and GUI applications
│   │       ├── security.nix   # Security and VPN tools
│   │       ├── gaming.nix     # Gaming optimizations
│   │       └── srv.nix        # Server configurations
│   ├── services/              # Service configurations
│   └── hardware/              # Hardware-specific settings
├── profiles/                  # High-level system profiles
└── tests/                    # System tests
```

## Profile System

### Development Profile

```nix
{
  profiles.dev = {
    enable = true;
    tools = {
      enable = true;  # Basic dev tools
      nix = true;     # Nix development
      shell = true;   # Shell utilities
    };
  };
}
```

### Desktop Profile

```nix
{
  profiles.desktop = {
    enable = true;
    apps = {
      browsers.enable = true;      # Firefox, Chromium
      communication.enable = true;  # Discord, Teams
      media.enable = true;         # VLC, media tools
    };
    wm.hyprland.enable = true;     # Modern Wayland compositor
  };
}
```

### Security Profile

```nix
{
  profiles.security = {
    enable = true;
    vpn = {
      enable = true;
      proton.enable = true;    # ProtonVPN
      tailscale.enable = true; # Tailscale mesh VPN
    };
    tools = {
      enable = true;
      onepassword.enable = true; # 1Password
      tor.enable = true;         # Tor Browser
    };
  };
}
```

## Quick Start

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/nix-config.git
   cd nix-config
   ```

2. Enable desired profiles in your `configuration.nix`:

   ```nix
   {
     profiles = {
       dev = {
         enable = true;
         tools.enable = true;
       };
       desktop = {
         enable = true;
         apps.browsers.enable = true;
       };
       security = {
         enable = true;
         vpn.enable = true;
       };
     };
   }
   ```

3. Apply the configuration:
   ```bash
   sudo nixos-rebuild switch --flake .#
   ```

## Development

1. Install pre-commit hooks:

   ```bash
   nix develop
   pre-commit install
   ```

2. Make changes:

   - Follow the module system structure
   - Add tests for new features
   - Update documentation

3. Test your changes:

   ```bash
   # Test all profiles
   nix flake check

   # Test specific profile
   nix build .#nixosTests.dev
   ```

## Best Practices

1. Use upstream modules when available
2. Follow the profile system structure
3. Document feature flags and options
4. Add tests for new functionality
5. Keep profiles focused and composable

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests and documentation
4. Submit a pull request

## License

MIT - See LICENSE file for details

## Acknowledgments

- NixOS community
- Contributors
- Testing frameworks
- Documentation tools
