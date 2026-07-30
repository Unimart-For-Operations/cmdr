# Lazygit — TUI for git operations
{ ... }:

{
  programs.lazygit = {
    enable = true;

    settings = {
      notARepository = "quit";
      promptToReturnFromSubprocess = false;

      git = {
        pagers = [
          {
            name = "difftastic";
            command = "difft --color=always --display=side-by-side --syntax-highlight=off";
          }
        ];
      };

      gui = {
        portraitMode = "never";
        sidePanelWidth = 0.21;
      };

      keybinding = {
        universal = {
          prevItem = "<up>";
          nextItem = "<down>";
          prevItem-alt = "k";
          nextItem-alt = "j";
        };
      };

      os = {
        edit = "$EDITOR {{filename}}";
      };
    };
  };
}
