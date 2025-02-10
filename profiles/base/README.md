# Base Profile

The base profile provides core system settings and security configurations that serve as a foundation for all other profiles. It implements essential functionality while following the principle of composition over inheritance.

## Features

### Core System Settings

- Nix store optimization
- Garbage collection
- Flakes support
- Trusted user management

### Security Features

- PAM configuration
- AppArmor support
- Audit daemon
- System hardening options
- Kernel security features

### System Optimization

- ZRAM swap configuration
- Kernel parameter tuning
- Resource limits management

## Usage

Enable the base profile in your NixOS configuration:

```nix
{
  profiles.base = {
    enable = true;
    security = {
      enable = true;
      hardening = true;
    };
  };
}
```

## Feature Flags

| Flag                 | Description                       | Default |
| -------------------- | --------------------------------- | ------- |
| `enable`             | Enable the base profile           | `false` |
| `security.enable`    | Enable enhanced security features | `false` |
| `security.hardening` | Enable system hardening           | `false` |

## Dependencies

The base profile requires:

- NixOS 24.05 or later
- Flakes enabled
- systemd

## Testing

Run the base profile tests:

```bash
nix build .#nixosTests.base
```

## Integration

The base profile is designed to be composed with other profiles:

```nix
{
  profiles = {
    base.enable = true;
    dev.enable = true;  # Development profile
    gaming.enable = true;  # Gaming profile
  };
}
```

## Best Practices

1. Always enable the base profile before other profiles
2. Review security settings before deployment
3. Monitor system logs for security events
4. Regularly update system packages
5. Backup configuration before major changes

## Troubleshooting

Common issues and solutions:

1. **System won't boot with hardening enabled**

   - Check kernel parameters
   - Verify hardware compatibility
   - Review AppArmor profiles

2. **Performance issues**
   - Adjust ZRAM configuration
   - Review resource limits
   - Check system logs

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a pull request

## License

MIT - See LICENSE file for details
