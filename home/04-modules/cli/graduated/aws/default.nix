# AWS CLI and related tools
{ pkgs, lib, ... }:

{
  imports = [
    ./helpers.nix # AWS shell helper functions (a, ak, show_aws_access)
  ];

  home.packages = with pkgs; [
    awscli2 # AWS CLI v2
    ssm-session-manager-plugin # AWS Session Manager plugin for SSM
  ];

  # Granted CLI requires the assume command to be sourced as an alias
  # to properly export AWS environment variables back to the shell
  # See: https://docs.commonfate.io/granted/internals/shell-alias
  programs.zsh.shellAliases = {
    assume = "source assume";
    asts = ''echo "$AWS_PROFILE - $(aws sts get-caller-identity --query "Account" --output text)"'';

    # AWS Start Session
    ss = let dir = "$HOME/.aws/start-session"; in
      "cd ${dir}; source .venv/bin/activate; python3 ${dir}/start-session.py";
  };

  # Tell Granted that the alias is already configured (managed by Nix)
  home.sessionVariables = {
    GRANTED_ALIAS_CONFIGURED = "true";
  };
}
