FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install base requirements
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    git \
    sudo \
    curl \
    wget \
    xz-utils \
    ca-certificates \
    lsb-release \
    zsh \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Go toolchain (required to build unimart). go.mod requires >= 1.25.5,
# newer than Ubuntu 24.04's apt golang (1.22), so use the official binary tarball.
RUN curl -fsSL https://go.dev/dl/go1.25.5.linux-amd64.tar.gz -o /tmp/go.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Create user with sudo privileges and zsh as default shell.
# The base image ships a default `ubuntu` user at uid 1000; remove it so
# nixuser can take uid 1000 and match the host user — keeping the mount-owner
# uid aligned with the user inside the container.
RUN userdel -r ubuntu 2>/dev/null || true && \
    useradd -m -u 1000 -G sudo -s /bin/zsh nixuser && \
    echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch to user
USER nixuser
WORKDIR /home/nixuser

# Create Nix config directory and pre-configure for Docker environment
RUN mkdir -p /home/nixuser/.config/nix && \
    echo 'sandbox = false' > /home/nixuser/.config/nix/nix.conf && \
    echo 'filter-syscalls = false' >> /home/nixuser/.config/nix/nix.conf && \
    echo 'experimental-features = nix-command flakes' >> /home/nixuser/.config/nix/nix.conf

# Create Nix installation script
# Note: Nix cannot be installed during Docker build on Apple Silicon due to seccomp/QEMU limitations
# This will be run automatically on first container start
RUN echo '#!/bin/bash' > /home/nixuser/install-nix.sh && \
    echo 'set -e' >> /home/nixuser/install-nix.sh && \
    echo 'echo "Installing Nix via Determinate Systems installer..."' >> /home/nixuser/install-nix.sh && \
    echo 'curl --proto "=https" --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --init none --no-confirm' >> /home/nixuser/install-nix.sh && \
    echo '. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' >> /home/nixuser/install-nix.sh && \
    echo 'echo ""' >> /home/nixuser/install-nix.sh && \
    echo 'echo "Nix installed: $(nix --version)"' >> /home/nixuser/install-nix.sh && \
    echo 'echo ""' >> /home/nixuser/install-nix.sh && \
    chmod +x /home/nixuser/install-nix.sh

# Add Nix to zshrc (will work after installation via Determinate Systems installer)
RUN touch /home/nixuser/.zshrc && \
    echo '' >> /home/nixuser/.zshrc && \
    echo '# Load Nix daemon profile (Determinate Systems multi-user install)' >> /home/nixuser/.zshrc && \
    echo 'if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then' >> /home/nixuser/.zshrc && \
    echo '  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' >> /home/nixuser/.zshrc && \
    echo 'fi' >> /home/nixuser/.zshrc

# Create welcome script
RUN echo '#!/bin/zsh' > /home/nixuser/welcome.sh && \
    echo 'echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"' >> /home/nixuser/welcome.sh && \
    echo 'echo "Ubuntu 24.04 LTS Test Environment"' >> /home/nixuser/welcome.sh && \
    echo 'echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"' >> /home/nixuser/welcome.sh && \
    echo 'echo ""' >> /home/nixuser/welcome.sh && \
    echo 'if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then' >> /home/nixuser/welcome.sh && \
    echo '  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' >> /home/nixuser/welcome.sh && \
    echo 'fi' >> /home/nixuser/welcome.sh && \
    echo 'if command -v nix &> /dev/null; then' >> /home/nixuser/welcome.sh && \
    echo '  echo "Nix: $(nix --version)"' >> /home/nixuser/welcome.sh && \
    echo '  echo "Shell: zsh"' >> /home/nixuser/welcome.sh && \
    echo '  echo "Platform: $(uname -m) $(lsb_release -ds 2>/dev/null || echo Ubuntu)"' >> /home/nixuser/welcome.sh && \
    echo '  echo ""' >> /home/nixuser/welcome.sh && \
    echo '  echo "Quick start:"' >> /home/nixuser/welcome.sh && \
    echo '  echo "  cd /workspace"' >> /home/nixuser/welcome.sh && \
    echo '  echo "  nix flake check                                             # Validate flake"' >> /home/nixuser/welcome.sh && \
    echo '  echo "  nix run .#homeConfigurations.cmdr.activationPackage         # Apply cmdr config"' >> /home/nixuser/welcome.sh && \
    echo 'else' >> /home/nixuser/welcome.sh && \
    echo '  echo "Nix not installed - run ~/install-nix.sh to install"' >> /home/nixuser/welcome.sh && \
    echo '  echo ""' >> /home/nixuser/welcome.sh && \
    echo 'fi' >> /home/nixuser/welcome.sh && \
    echo 'echo ""' >> /home/nixuser/welcome.sh && \
    echo 'echo "User: $(whoami)"' >> /home/nixuser/welcome.sh && \
    echo 'echo "Working directory: $(pwd)"' >> /home/nixuser/welcome.sh && \
    echo 'echo "Repo mounted at: /workspace"' >> /home/nixuser/welcome.sh && \
    echo 'echo ""' >> /home/nixuser/welcome.sh && \
    echo 'echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"' >> /home/nixuser/welcome.sh && \
    chmod +x /home/nixuser/welcome.sh

# Create entrypoint script that auto-installs Nix on first run
RUN echo '#!/bin/bash' > /home/nixuser/entrypoint.sh && \
    echo 'set -e' >> /home/nixuser/entrypoint.sh && \
    echo '' >> /home/nixuser/entrypoint.sh && \
    echo '# Check if Nix is installed (Determinate Systems multi-user install)' >> /home/nixuser/entrypoint.sh && \
    echo 'if ! command -v nix &> /dev/null; then' >> /home/nixuser/entrypoint.sh && \
    echo '  /home/nixuser/install-nix.sh' >> /home/nixuser/entrypoint.sh && \
    echo 'fi' >> /home/nixuser/entrypoint.sh && \
    echo '' >> /home/nixuser/entrypoint.sh && \
    echo '# Show welcome message' >> /home/nixuser/entrypoint.sh && \
    echo '/home/nixuser/welcome.sh' >> /home/nixuser/entrypoint.sh && \
    echo '' >> /home/nixuser/entrypoint.sh && \
    echo '# Start zsh interactively, or keep alive if no TTY (e.g. podman-compose up -d)' >> /home/nixuser/entrypoint.sh && \
    echo 'if [ -t 0 ]; then' >> /home/nixuser/entrypoint.sh && \
    echo '  exec /bin/zsh' >> /home/nixuser/entrypoint.sh && \
    echo 'else' >> /home/nixuser/entrypoint.sh && \
    echo '  exec sleep infinity' >> /home/nixuser/entrypoint.sh && \
    echo 'fi' >> /home/nixuser/entrypoint.sh && \
    chmod +x /home/nixuser/entrypoint.sh

# Default command - use entrypoint
CMD ["/home/nixuser/entrypoint.sh"]
