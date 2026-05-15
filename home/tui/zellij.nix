_: {
  programs.zellij = {
    enable = true;

    ## The Home Manager shell integrations auto-start Zellij. Keep startup explicit like the existing tmux workflow.
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;

    settings = {
      default_mode = "normal";
      default_layout = "default";

      pane_frames = true;
      auto_layout = true;
      mouse_mode = true;
      scroll_buffer_size = 10000;

      session_serialization = true;
      serialize_pane_viewport = true;
      scrollback_lines_to_serialize = 2000;

      copy_clipboard = "system";
      copy_on_select = true;

      theme = "catppuccin-mocha";
      show_startup_tips = false;
      show_release_notes = false;
      on_force_close = "detach";
    };

    extraConfig = ''
      themes {
          catppuccin-mocha {
              fg 205 214 244
              bg 30 30 46
              black 17 17 27
              red 243 139 168
              green 166 227 161
              yellow 249 226 175
              blue 137 180 250
              magenta 203 166 247
              cyan 137 220 235
              white 205 214 244
              orange 250 179 135
          }
      }

      keybinds clear-defaults=true {
          locked {
              bind "Ctrl g" { SwitchToMode "Normal"; }
              bind "Ctrl a" "Ctrl t" { SwitchToMode "Tmux"; }
          }

          resize {
              bind "Enter" "Esc" { SwitchToMode "Normal"; }
              bind "h" "Left" { Resize "Increase Left"; }
              bind "j" "Down" { Resize "Increase Down"; }
              bind "k" "Up" { Resize "Increase Up"; }
              bind "l" "Right" { Resize "Increase Right"; }
              bind "H" { Resize "Decrease Left"; }
              bind "J" { Resize "Decrease Down"; }
              bind "K" { Resize "Decrease Up"; }
              bind "L" { Resize "Decrease Right"; }
              bind "=" "+" { Resize "Increase"; }
              bind "-" { Resize "Decrease"; }
          }

          pane {
              bind "Ctrl p" { SwitchToMode "Normal"; }
              bind "h" "Left" { MoveFocus "Left"; }
              bind "j" "Down" { MoveFocus "Down"; }
              bind "k" "Up" { MoveFocus "Up"; }
              bind "l" "Right" { MoveFocus "Right"; }
              bind "p" { SwitchFocus; }
              bind "n" { NewPane; SwitchToMode "Normal"; }
              bind "s" "d" { NewPane "Down"; SwitchToMode "Normal"; }
              bind "v" "r" { NewPane "Right"; SwitchToMode "Normal"; }
              bind "x" { CloseFocus; SwitchToMode "Normal"; }
              bind "f" "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
              bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
              bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
              bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0; }
              bind "i" { TogglePanePinned; SwitchToMode "Normal"; }
          }

          move {
              bind "Ctrl h" { SwitchToMode "Normal"; }
              bind "n" "Tab" { MovePane; }
              bind "p" { MovePaneBackwards; }
              bind "h" "Left" { MovePane "Left"; }
              bind "j" "Down" { MovePane "Down"; }
              bind "k" "Up" { MovePane "Up"; }
              bind "l" "Right" { MovePane "Right"; }
          }

          tab {
              bind "Ctrl t" { SwitchToMode "Normal"; }
              bind "r" "," { SwitchToMode "RenameTab"; TabNameInput 0; }
              bind "h" "Left" "Up" "k" "p" { GoToPreviousTab; }
              bind "l" "Right" "Down" "j" "n" { GoToNextTab; }
              bind "c" "n" { NewTab; SwitchToMode "Normal"; }
              bind "x" { CloseTab; SwitchToMode "Normal"; }
              bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
              bind "b" { BreakPane; SwitchToMode "Normal"; }
              bind "]" { BreakPaneRight; SwitchToMode "Normal"; }
              bind "[" { BreakPaneLeft; SwitchToMode "Normal"; }
              bind "1" { GoToTab 1; SwitchToMode "Normal"; }
              bind "2" { GoToTab 2; SwitchToMode "Normal"; }
              bind "3" { GoToTab 3; SwitchToMode "Normal"; }
              bind "4" { GoToTab 4; SwitchToMode "Normal"; }
              bind "5" { GoToTab 5; SwitchToMode "Normal"; }
              bind "6" { GoToTab 6; SwitchToMode "Normal"; }
              bind "7" { GoToTab 7; SwitchToMode "Normal"; }
              bind "8" { GoToTab 8; SwitchToMode "Normal"; }
              bind "9" { GoToTab 9; SwitchToMode "Normal"; }
              bind "Tab" { ToggleTab; }
          }

          scroll {
              bind "Ctrl s" { SwitchToMode "Normal"; }
              bind "e" { EditScrollback; SwitchToMode "Normal"; }
              bind "s" "/" { SwitchToMode "EnterSearch"; SearchInput 0; }
              bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
              bind "j" "Down" { ScrollDown; }
              bind "k" "Up" { ScrollUp; }
              bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
              bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
              bind "d" { HalfPageScrollDown; }
              bind "u" { HalfPageScrollUp; }
          }

          search {
              bind "Ctrl s" { SwitchToMode "Normal"; }
              bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
              bind "j" "Down" { ScrollDown; }
              bind "k" "Up" { ScrollUp; }
              bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
              bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
              bind "d" { HalfPageScrollDown; }
              bind "u" { HalfPageScrollUp; }
              bind "n" { Search "down"; }
              bind "p" { Search "up"; }
              bind "c" { SearchToggleOption "CaseSensitivity"; }
              bind "w" { SearchToggleOption "Wrap"; }
              bind "o" { SearchToggleOption "WholeWord"; }
          }

          entersearch {
              bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
              bind "Enter" { SwitchToMode "Search"; }
          }

          renametab {
              bind "Ctrl c" { SwitchToMode "Normal"; }
              bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
          }

          renamepane {
              bind "Ctrl c" { SwitchToMode "Normal"; }
              bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
          }

          session {
              bind "Ctrl o" { SwitchToMode "Normal"; }
              bind "Ctrl s" { SwitchToMode "Scroll"; }
              bind "d" { Detach; }
              bind "w" {
                  LaunchOrFocusPlugin "session-manager" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "c" {
                  LaunchOrFocusPlugin "configuration" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "p" {
                  LaunchOrFocusPlugin "plugin-manager" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
              bind "l" {
                  LaunchOrFocusPlugin "zellij:layout-manager" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
          }

          tmux {
              bind "[" { SwitchToMode "Scroll"; }
              bind "Ctrl a" { Write 1; SwitchToMode "Normal"; }
              bind "Ctrl t" { Write 20; SwitchToMode "Normal"; }
              bind "\"" "s" { NewPane "Down"; SwitchToMode "Normal"; }
              bind "%" "v" { NewPane "Right"; SwitchToMode "Normal"; }
              bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
              bind "c" { NewTab; SwitchToMode "Normal"; }
              bind "," { SwitchToMode "RenameTab"; TabNameInput 0; }
              bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }
              bind "n" { GoToNextTab; SwitchToMode "Normal"; }
              bind "1" { GoToTab 1; SwitchToMode "Normal"; }
              bind "2" { GoToTab 2; SwitchToMode "Normal"; }
              bind "3" { GoToTab 3; SwitchToMode "Normal"; }
              bind "4" { GoToTab 4; SwitchToMode "Normal"; }
              bind "5" { GoToTab 5; SwitchToMode "Normal"; }
              bind "6" { GoToTab 6; SwitchToMode "Normal"; }
              bind "7" { GoToTab 7; SwitchToMode "Normal"; }
              bind "8" { GoToTab 8; SwitchToMode "Normal"; }
              bind "9" { GoToTab 9; SwitchToMode "Normal"; }
              bind "Left" "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
              bind "Right" "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
              bind "Down" "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
              bind "Up" "k" { MoveFocus "Up"; SwitchToMode "Normal"; }
              bind "o" { FocusNextPane; SwitchToMode "Normal"; }
              bind "d" { Detach; }
              bind "Space" { NextSwapLayout; SwitchToMode "Normal"; }
              bind "x" { CloseFocus; SwitchToMode "Normal"; }
              bind "w" { SwitchToMode "Session"; }
              bind "t" { SwitchToMode "Tab"; }
              bind "m" { SwitchToMode "Move"; }
              bind "M" { TogglePaneFrames; SwitchToMode "Normal"; }
              bind "r" {
                  LaunchOrFocusPlugin "configuration" {
                      floating true
                      move_to_focused_tab true
                  };
                  SwitchToMode "Normal"
              }
          }

          shared_except "locked" {
              bind "Ctrl g" { SwitchToMode "Locked"; }
              bind "Ctrl q" { Quit; }
              bind "Ctrl a" "Ctrl t" { SwitchToMode "Tmux"; }
              bind "Ctrl Alt h" { MoveFocusOrTab "Left"; }
              bind "Ctrl Alt l" { MoveFocusOrTab "Right"; }
              bind "Ctrl Alt j" { MoveFocus "Down"; }
              bind "Ctrl Alt k" { MoveFocus "Up"; }
              bind "Ctrl Alt n" { GoToNextTab; }
              bind "Ctrl Alt p" { GoToPreviousTab; }
              bind "Alt f" { ToggleFloatingPanes; }
              bind "Alt n" { NewPane; }
              bind "Alt i" { MoveTab "Left"; }
              bind "Alt o" { MoveTab "Right"; }
              bind "Alt h" { MoveFocusOrTab "Left"; }
              bind "Alt l" { MoveFocusOrTab "Right"; }
              bind "Alt j" "Alt Down" { MoveFocus "Down"; }
              bind "Alt k" "Alt Up" { MoveFocus "Up"; }
              bind "Alt =" "Alt +" { Resize "Increase"; }
              bind "Alt -" { Resize "Decrease"; }
              bind "Alt [" { PreviousSwapLayout; }
              bind "Alt ]" { NextSwapLayout; }
              bind "Alt p" { TogglePaneInGroup; }
              bind "Alt Shift p" { ToggleGroupMarking; }
          }

          shared_except "normal" "locked" {
              bind "Enter" "Esc" { SwitchToMode "Normal"; }
          }

          shared_except "pane" "locked" {
              bind "Ctrl p" { SwitchToMode "Pane"; }
          }

          shared_except "resize" "locked" {
              bind "Alt r" { SwitchToMode "Resize"; }
          }

          shared_except "scroll" "locked" {
              bind "Ctrl s" { SwitchToMode "Scroll"; }
          }

          shared_except "session" "locked" {
              bind "Ctrl o" { SwitchToMode "Session"; }
          }

          shared_except "move" "locked" {
              bind "Ctrl h" { SwitchToMode "Move"; }
          }

          shared_except "tmux" "locked" {
              bind "Ctrl a" "Ctrl t" { SwitchToMode "Tmux"; }
          }
      }
    '';
  };
}
