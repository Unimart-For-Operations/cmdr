---
source: idpbuilder-org
synced: 2026-03-30
---
# Secret Management with sops-nix

This repository uses [sops-nix](https://github.com/Mic92/sops-nix) for secure secret management. Secrets are encrypted using age keys and never committed in plaintext.

## Overview

- **Encryption**: Secrets are encrypted with [age](https://github.com/FiloSottile/age) encryption
- **Storage**: Encrypted secrets stored in `secrets/` directory
- **Access**: Each host has its own age key for decryption
- **Integration**: Secrets automatically decrypted and made available as environment variables via Home Manager

## Architecture

### Components

1. **Age Keys**: Each host has a unique age key pair
   - Private key: `~/.config/sops/age/keys.txt` (never committed)
   - Public key: Listed in `.sops.yaml` (safe to commit)

2. **Encrypted Secrets**: YAML files in `secrets/` directory
   - Example: `secrets/universal/env.yaml`
   - Encrypted with age, safe to commit

3. **sops-nix Module**: Integrated into flake.nix
   - Automatically decrypts secrets at activation
   - Exposes secrets as environment variables

## Quick Start

### For New Users

If you're cloning this repository for the first time:

1. **Generate an age key** for your host:
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

2. **Get your public key**:
   ```bash
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

3. **Add your public key** to `.sops.yaml`:
   ```yaml
   keys:
     - &your-host age1your_public_key_here
   
   creation_rules:
     - path_regex: secrets/.*\.yaml$
       key_groups:
         - age:
             - *your-host
   ```

4. **Update secrets** to include your key:
   ```bash
   sops updatekeys secrets/universal/env.yaml
   ```

### For Existing Hosts

If you're setting up an existing host listed in `.sops.yaml`:

1. **Locate your host's age key** from the secure backup location:
   - Keys are stored in a secure backup location outside this repo
   - Example: `age-keys/apple-macbook-m3-pro.txt`

2. **Install the key**:
   ```bash
   mkdir -p ~/.config/sops/age
   cp /path/to/backup/age-keys/your-host.txt ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```

3. **Verify decryption**:
   ```bash
   sops -d secrets/universal/env.yaml
   ```

## Managing Secrets

### Viewing Secrets

```bash
# View decrypted secrets
sops secrets/universal/env.yaml

# View in JSON format
sops -d --output-type json secrets/universal/env.yaml
```

### Adding New Secrets

```bash
# Edit existing secret file
sops secrets/universal/env.yaml

# Create new secret file
sops secrets/new-category/secrets.yaml
```

**Note**: New files must match patterns in `.sops.yaml` to be encrypted correctly.

### Updating Secrets

```bash
# Edit a secret (will re-encrypt automatically)
sops secrets/universal/env.yaml

# Update keys after adding a new host to .sops.yaml
sops updatekeys secrets/universal/env.yaml
```

### Rotating Secrets

When rotating secrets (e.g., after a security incident):

1. **Generate new credentials** from the service provider
2. **Update encrypted files**:
   ```bash
    sops secrets/universal/env.yaml
   # Update the values in the editor
   ```
3. **Commit and deploy**:
   ```bash
   git add secrets/
   git commit -m "security: rotate compromised credentials"
   git push
   ```
4. **Rebuild systems**:
   ```bash
   darwin-rebuild switch --flake .
   # or
   home-manager switch --flake .
   ```

## Secret Files

### Current Secret Files

- `secrets/universal/env.yaml`: Shared environment variables across hosts
  - Machine-agnostic secrets only

### File Structure

Encrypted secret files follow this structure:

```yaml
# secrets/category/env.yaml
SECRET_NAME: secret_value
ANOTHER_SECRET: another_value
```

## Host Keys

### Current Hosts

The following hosts have age keys configured:

1. **apple-macbook-m3-pro** (Mortimers-MacBook-Pro.local)
2. **apple-studio-m2-max** (Mortimers-Mac-Studio.local)
3. **cachyos** (Linux workstation)
4. **cmdr** (Commander host)

### Key Management

- **Private keys**: Stored in `~/.config/sops/age/keys.txt` on each host
- **Backup location**: Stored securely outside this repo (never committed to git)
- **Public keys**: Listed in `.sops.yaml` in the repository

**IMPORTANT**: Private keys should NEVER be committed to git!

## Integration with Home Manager

Secrets are automatically integrated into your environment via Home Manager:

```nix
{ config, ... }:

{
  home.sessionVariables = {
    EXAMPLE_TOKEN = "$(cat ${config.sops.secrets.example_token.path})";
  };

  sops = {
    defaultSopsFile = ../../secrets/universal/env.yaml;
    secrets.example_token = { };
  };
}
```

Alternatively, for environment variables, use the sops-nix templating feature:

```nix
sops.templates."app-env".content = ''
  export EXAMPLE_TOKEN="${config.sops.placeholder."example_token"}"
'';

home.sessionVariables = {
  APP_ENV_FILE = config.sops.templates."app-env".path;
};
```

## Security Best Practices

### DO

- ✅ Always use sops to edit secret files
- ✅ Keep age private keys secure (600 permissions)
- ✅ Back up age keys to a secure location
- ✅ Add `.sops.yaml` to git (it contains public keys only)
- ✅ Commit encrypted `.yaml` files in `secrets/`
- ✅ Use the gitleaks pre-commit hook
- ✅ Rotate secrets after potential compromise

### DON'T

- ❌ Never commit age private keys
- ❌ Never edit encrypted files directly (use `sops` command)
- ❌ Never commit plaintext secrets
- ❌ Never share age private keys via insecure channels
- ❌ Don't disable the pre-commit hook without good reason

## Troubleshooting

### Cannot Decrypt Secrets

**Error**: `MAC mismatch` or `failed to get data key`

**Solution**: Make sure your age key is properly installed:
```bash
ls -la ~/.config/sops/age/keys.txt
# Should show permissions: -rw------- (600)
```

### Wrong Host Key

**Error**: Secret decrypts but shows wrong values

**Solution**: Verify you're using the correct age key for your hostname:
```bash
hostname
# Should match one of: apple-macbook-m3-pro, apple-studio-m2-max, cachyos, cmdr
```

### Adding Secrets to New Files

**Error**: `sops` doesn't encrypt new file

**Solution**: Ensure file path matches a pattern in `.sops.yaml`:
```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$  # Must match your file path
```

### Pre-commit Hook Failures

**Error**: Gitleaks detects false positive

**Solution**: Add exception to `.gitleaks.toml`:
```toml
[allowlist]
regexes = [
  '''your-pattern-here''',
]
```

## Migration from Plaintext

This repository previously had hardcoded secrets. Here's what was done:

1. **Extracted secrets** to encrypted sops files
2. **Rewrote git history** using BFG Repo-Cleaner to remove plaintext secrets
3. **Added pre-commit hooks** to prevent future secret leaks
4. **Updated modules** to use sops-encrypted secrets

If you cloned before this migration, you should:
```bash
# Re-clone the repository after force push
cd ..
mv dev-control-plane dev-control-plane.old
git clone git@github.com:Unimart-For-Operations/cmdr.git
```

## Additional Resources

- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [age Encryption Tool](https://github.com/FiloSottile/age)
- [sops (Secrets OPerationS)](https://github.com/mozilla/sops)
- [Gitleaks Secret Scanner](https://github.com/gitleaks/gitleaks)

## Support

For issues or questions:
1. Check this documentation first
2. Review sops-nix issues on GitHub
3. Contact the repository maintainer
