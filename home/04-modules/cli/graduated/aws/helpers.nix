# AWS Shell Helper Functions
# Generic AWS utilities for profile management, SSO, and EKS
{ lib, ... }:

{
  programs.zsh.initContent = lib.mkOrder 750 ''
    # ══════════════════════════════════════════════════════════════════════
    # AWS HELPER FUNCTIONS
    # ══════════════════════════════════════════════════════════════════════

    # ── AWS 'as' shortcut ────────────────────────────────────────────────
    # Uses a function (not alias) to override the /nix/store clang 'as'
    # binary. Functions take precedence over PATH.
    function as() {
      source assume --export-sso-token "$@"
    }

    # ── AWS Profile Management ───────────────────────────────────────────

    # Assume AWS profile with fzf - select AWS profile interactively
    # Usage: a [search_term]
    # Requires: assume (Granted CLI), fzf
    function a() {
      # Set this to prevent Granted from prompting about alias configuration
      # We use 'source assume' explicitly, which is what the alias does
      export GRANTED_ALIAS_CONFIGURED="true"
      
      local search_term="''${1:-}"
      local selected_profile
      
      if [ -n "$search_term" ]; then
        selected_profile=$(sed -n "s/\[profile \(.*\)\]/\1/gp" ~/.aws/config | grep "$search_term" | fzf --reverse --height 20%)
      else
        selected_profile=$(sed -n "s/\[profile \(.*\)\]/\1/gp" ~/.aws/config | fzf --reverse --height 20%)
      fi
      
      if [ -n "$selected_profile" ]; then
        export AWS_PROFILE="$selected_profile"
        source assume -t -c "$AWS_PROFILE"
        echo "$AWS_PROFILE - $(aws sts get-caller-identity --query "Account" --output text 2>/dev/null || echo "Unable to get account info")"
      else
        echo "No profile selected."
        return 1
      fi
    }

    # ── AWS + Kubernetes Integration ─────────────────────────────────────

    # Assume AWS profile and connect to EKS cluster
    # Usage: ak [search_term]
    # Requires: assume (Granted CLI), fzf, aws, kubectl
    function ak() {
      # Set this to prevent Granted from prompting about alias configuration
      # We use 'source assume' explicitly, which is what the alias does
      export GRANTED_ALIAS_CONFIGURED="true"
      
      local search_term="''${1:-}"
      local selected_profile
      
      if [ -n "$search_term" ]; then
        selected_profile=$(sed -n "s/\[profile \(.*\)\]/\1/gp" ~/.aws/config | grep "$search_term" | fzf --reverse --height 20%)
      else
        selected_profile=$(sed -n "s/\[profile \(.*\)\]/\1/gp" ~/.aws/config | fzf --reverse --height 20%)
      fi
      
      if [ -n "$selected_profile" ]; then
        export AWS_PROFILE="$selected_profile"
        source assume -t "$AWS_PROFILE"
      else
        echo "No profile selected."
        return 1
      fi

      CLUSTER=$(aws eks list-clusters --output text | awk '{print $2}' | fzf --reverse)
      echo; aws eks update-kubeconfig --name $CLUSTER
    }

    # ── AWS SSO Account Management ───────────────────────────────────────

    # Show AWS SSO accounts you have access to
    # Usage: show_aws_access
    # Requires: AWS_SSO_DOMAIN environment variable (e.g., "example.awsapps.com")
    # Requires: aws, jq
    function show_aws_access() {
      if [ -z "$AWS_SSO_DOMAIN" ]; then
        echo "Error: AWS_SSO_DOMAIN environment variable not set"
        echo "Example: export AWS_SSO_DOMAIN='example.awsapps.com'"
        return 1
      fi

      echo "Checking your AWS SSO access..."
      
      local token_file=$(find ~/.aws/sso/cache -name "*.json" -exec grep -l "$AWS_SSO_DOMAIN" {} \; | head -1)
      
      if [ -z "$token_file" ]; then
        echo "No SSO token found for domain: $AWS_SSO_DOMAIN"
        echo "Run 'assume' or 'aws sso login' to authenticate."
        return 1
      fi
      
      local access_token=$(cat "$token_file" | jq -r .accessToken 2>/dev/null)
      
      if [ -z "$access_token" ] || [ "$access_token" = "null" ]; then
        echo "Invalid SSO token. Run 'assume' or 'aws sso login' to re-authenticate."
        return 1
      fi
      
      echo "Found valid SSO token for $AWS_SSO_DOMAIN"
      echo ""
      echo "Accounts you have access to:"
      echo "================================"
      
      aws sso list-accounts --access-token "$access_token" --query 'accountList[].{Name:accountName,ID:accountId}' --output table
    }
  '';
}
