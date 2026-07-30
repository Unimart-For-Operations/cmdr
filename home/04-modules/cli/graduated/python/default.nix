# Python development environment
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    uv # Python package/project manager (manages its own Python versions)
  ];

  # ── Shell aliases ──────────────────────────────────────────────────────────
  # uv venv shortcuts
  programs.zsh.shellAliases = {
    venv = "uv venv"; # Create .venv in current dir
    va = "source .venv/bin/activate"; # Activate local venv
    vd = "deactivate"; # Deactivate venv
    pipi = "uv pip install"; # Install package(s)
    pipu = "uv pip install --upgrade"; # Upgrade package(s)
    pipf = "uv pip freeze"; # List installed packages
    pipr = "uv pip install -r requirements.txt"; # Install from requirements
  };
}
