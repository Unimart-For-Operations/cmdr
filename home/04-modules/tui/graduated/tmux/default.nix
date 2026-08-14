{ config, pkgs, lib, ... }:

let
  # On hosts running the DMS desktop shell, tmux colors come from DMS's matugen
  # (dank-theme.conf, regenerated on every theme change).
  isDms = (config.programs.dank-material-shell or { }).enable or false;
  # On DMS hosts, source the matugen-generated theme (regenerated on every theme
  # change). if-shell guards against the file not existing yet (e.g. first boot
  # before matugen has run).
  dmsThemeSource =
    if isDms then ''
      # DMS matugen theme
      if-shell "test -f ~/.config/tmux/dank-theme.conf" "source-file ~/.config/tmux/dank-theme.conf"
    '' else "";
in
{
  # Import layout scripts module
  imports = [
    ./layouts.nix
  ];

  # Enable tmux with Home Manager
  programs.tmux = {
    enable = true;

    # Terminal settings
    terminal = "screen-256color";
    escapeTime = 10;
    historyLimit = 10000;

    # Mouse support
    mouse = true;

    # Start window and pane numbering at 1
    baseIndex = 1;

    # Remap prefix from 'C-b' to 'C-Space'
    prefix = "C-Space";

    # Additional tmux settings and keybindings
    extraConfig = ''
      # ============================================
      # Quality of Life Improvements
      # ============================================
      # Renumber windows when one is closed
      set -g renumber-windows on
      
      # Enable focus events (useful for vim/neovim)
      set -g focus-events on
      
      # Color support with true color
      set -ga terminal-overrides ",xterm-256color:Tc,screen-256color:Tc,tmux-256color:Tc"

      # ============================================
      # Pane Navigation (Vim-style)
      # ============================================
      # Switch panes using prefix + hjkl
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      
      # ============================================
      # Window/Pane Splitting
      # ============================================
      # Split panes using | and - (more intuitive)
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %
      
      # Create new window in current path
      bind c new-window -c "#{pane_current_path}"
      
      # ============================================
      # Pane Resizing
      # ============================================
      # Resize panes with prefix + arrow keys
      bind -r Left resize-pane -L 5
      bind -r Down resize-pane -D 5
      bind -r Up resize-pane -U 5
      bind -r Right resize-pane -R 5
      
      # ============================================
      # Status Bar Configuration
      # ============================================
      # Colors come from DMS's matugen on DMS hosts (dank-theme.conf); elsewhere
      # tmux uses its stock colors.
      # Update status bar every 5 seconds
      set -g status-interval 5
      
      # Status bar positioning
      set -g status-position top
      set -g status-justify left
      
      # Left side of status bar (session name)
      set -g status-left-length 40
      
      # Right side of status bar (includes continuum save indicator)
      set -g status-right '#{?#{continuum_status},#[fg=green]  #{continuum_status} ,}%d/%m %H:%M:%S '
      set -g status-right-length 60
      
      # Window status (inactive)
      setw -g window-status-format ' #I:#W#F '
      
      # Window status (active)
      setw -g window-status-current-format ' #I:#W#F '
      
      # Pane border colors
      set -g pane-border-lines single
      set -g pane-border-indicators off
      set -g pane-border-status off
      # Keep borders static (no active-pane highlighting)
      set -g pane-border-style default
      set -g pane-active-border-style default
      
      # ============================================
      # Copy Mode Configuration
      # ============================================
      # Use vim keybindings in copy mode
      setw -g mode-keys vi
      
      # Vim-style copy/paste
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      
      # ============================================
      # Reload Configuration
      # ============================================
      # Reload config file with prefix + r
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
      
      # ============================================
      # Additional Useful Keybindings
      # ============================================
      # Clear scrollback buffer with prefix + K
      bind K clear-history

      # Toggle synchronize-panes with prefix + S
      bind S set-window-option synchronize-panes
      ${dmsThemeSource}
      
      # ============================================
      # Sesh Session Management
      # ============================================
      # Sesh session switcher with fzf (prefix + T)
      # Shows all sessions, zoxide directories, and allows quick switching
      bind-key "T" run-shell "sesh connect \"$(
        sesh list -itz | fzf-tmux -p 55%,60% \
          --no-sort --border-label ' sesh ' --prompt '⚡  ' \
          --header '  ^a all ^t tmux ^g config ^x zoxide ^d tmux kill ^f find' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
          --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
          --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
          --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
          --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
          --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)'
      )\""
    '';

    # Tmux plugins
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = ''
          # Restore vim/neovim sessions
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-strategy-nvim 'session'
          
          # Capture pane contents
          set -g @resurrect-capture-pane-contents 'on'
          
          # Restore additional programs
          # ~prefix matches process name anywhere in the command string
          # ->  overrides the restore command (arrow syntax)
          # *   preserves original arguments on restore
          set -g @resurrect-processes 'ssh psql mysql sqlite3 "~lazygit" "~helix" "~nvim-astro->nvim-astro *" "~nvim" "~opencode"'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          # Automatic restore on tmux start
          set -g @continuum-restore 'on'
          
          # Auto-save interval (in minutes)
          set -g @continuum-save-interval '15'
        '';
      }
    ];
  };
}
