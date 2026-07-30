---
source: idpbuilder-org
synced: 2026-03-30
---
# Guides

How-to tutorials for common tasks.

## Adding Packages

To add a new CLI tool, find the appropriate module in `home/04-modules/cli/graduated/` and add the package:

```nix
# Example: adding a new CLI tool to home/04-modules/cli/graduated/core-utils/default.nix
home.packages = with pkgs; [
  your-package
];
```

Then apply: `make apply HOST=<name>`

## Creating a New Module

1. Create a new `.nix` file in the appropriate `home/04-modules/<category>/<tier>/` subdirectory
2. Import it from the parent `default.nix`
3. Add any new packages or configuration
4. Test with `make diff HOST=<name>` before applying

## Adding a New Host

```bash
make new-host DISTRO=macos NAME=my-new-mac
# or
make new-host DISTRO=arch NAME=my-new-arch
```

See [Bootstrap Guide](../Getting-Started/bootstrap.md) for full walkthrough.

## Platform-Specific Configuration

Platform differences belong in dedicated platform files (`home/01-platforms/darwin.nix` or `linux.nix`), **not** in shared modules. Never use `pkgs.stdenv.isDarwin` or `pkgs.stdenv.isLinux` conditionals inside modules — this is a core design principle.

See [Platforms Reference](../Reference/platforms.md) for supported platforms and architectures.
