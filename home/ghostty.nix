{ lib, ... }:

{
  # Ghostty loads both XDG and macOS-specific config files on macOS. Keep the
  # managed config in the XDG path so it works for personal and work machines.
  xdg.configFile."ghostty/config" = {
    force = true;
    text = ''
      # Follow macOS light/dark mode.
      theme = dark:GitHub Dark Default,light:GitHub Light Default

      font-size = 16

      window-height = 35
      window-width = 120
      window-save-state = never

      keybind = global:ctrl+grave_accent=toggle_quick_terminal
      keybind = shift+enter=text:\n
      adjust-cursor-thickness = 4
    '';
  };

  # Retire legacy macOS-specific Ghostty config files so they cannot override
  # the XDG config above. Back them up instead of deleting them outright.
  home.activation.migrateGhosttyMacOSConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    legacy_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"

    if [ -d "$legacy_dir" ]; then
      for name in config config.ghostty; do
        legacy_file="$legacy_dir/$name"

        if [ -e "$legacy_file" ] || [ -L "$legacy_file" ]; then
          backup="$legacy_file.before-home-manager"

          if [ -e "$backup" ] || [ -L "$backup" ]; then
            backup="$backup.$(date +%Y%m%d%H%M%S)"
          fi

          run mv "$legacy_file" "$backup"
        fi
      done
    fi
  '';
}
