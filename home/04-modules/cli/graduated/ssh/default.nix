# SSH client configuration
# Cross-platform baseline for all hosts.
# UseKeychain is macOS-only and rejected by OpenSSH on Linux — omit it entirely.
# Keys are added to the running ssh-agent (AddKeysToAgent) which works on all platforms.
{ ... }:

{
  programs.ssh = {
    enable = true;
    # Opt out of the deprecated top-level defaults; manage everything via settings.
    enableDefaultConfig = false;

    settings."*" = {
      ForwardAgent = false;
      AddKeysToAgent = "yes";
      ServerAliveInterval = 120;
      ServerAliveCountMax = 3;
      Compression = false;
      HashKnownHosts = false;
      IdentitiesOnly = false;
      UserKnownHostsFile = "~/.ssh/known_hosts";
      ControlMaster = "no";
      ControlPath = "~/.ssh/master-%r@%n:%p";
      ControlPersist = "no";
    };
  };
}
