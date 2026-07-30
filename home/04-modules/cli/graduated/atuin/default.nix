# Atuin — shell history with sync
{ ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;

    flags = [ "--disable-up-arrow" ];

    settings = {
      search_mode = "fuzzy";
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "session";

      show_preview = true;
      max_preview_height = 6;
      show_help = true;

      auto_sync = true;
      sync_frequency = "15m";

      show_time = false;
      style = "compact";
      exit_mode = "return-query";

      history_filter = [
        "^secret"
        "^password"
        "^export.*PASSWORD"
        "^aws.*secret"
        "^ls$"
        "^cd$"
        "^pwd$"
        "^clear$"
        "^exit$"
        "^history"
        "^atuin"
      ];

      secrets_filter = true;
      workspaces = true;
      update_check = false;
      word_jump_mode = "emacs";
      enter_accept = true;
    };
  };
}
