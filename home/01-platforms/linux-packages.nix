{ ... }:

{
  # Linux container runtime note:
  # unimart/idpbuilder uses Docker Engine from the OS package manager. Home
  # Manager installs the Docker CLI in the containerization module, but cannot
  # enable the rootful docker.service system daemon on non-NixOS hosts.
}
