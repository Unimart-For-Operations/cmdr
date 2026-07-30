# fzf — fuzzy finder for files, history, and interactive selection
{ ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Atuin owns Ctrl-R history search in zsh.
    historyWidget.zsh.command = "";
  };
}
