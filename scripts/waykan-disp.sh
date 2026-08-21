
usage() {
  cat << 'EOF'
Usage:
  waykan-disp [command] ...
Command:
  list
  set OUTPUT [mode MODE] [scale SCALE] [position X Y] [transform TRANSFORM]
  laptop
  right OUTPUT [X]
  left OUTPUT [X]
  above OUTPUT [Y]
  below OUTPUT [Y]
  off OUTPUT
  on OUTPUT

Examples:
  waykan-disp list
  waykan-disp right DP-1 1920
  waykan-disp set DP-1 scale 1.0 position 1920 0
  waykan-disp off HDMI-A-1
EOF
}

[[ $# -gt 0 ]] || { usage; exit 2; }

case "$1" in
  list)
    exec niri msg outputs
    ;;
  off|on)
    [[ $# -eq 2 ]] || { usage; exit 2; }
    exec niri msg output "$2" "$1"
    ;;
  set)
    [[ $# -ge 4 ]] || { usage; exit 2; }
    shift
    output="$1"
    shift
    while [[ $# -gt 0 ]]; do
      case "$1" in
        mode|scale|transform)
          [[ $# -ge 2 ]] || { usage; exit 2; }
          niri msg output "$output" "$1" "$2"
          shift 2
          ;;
        position)
          [[ $# -ge 3 ]] || { usage; exit 2; }
          niri msg output "$output" position set "$2" "$3"
          shift 3
          ;;
        *)
          usage
          exit 2
          ;;
      esac
    done
    ;;
  laptop)
    niri msg output eDP-1 on
    niri msg output eDP-1 scale 1.1
    niri msg output eDP-1 position set 0 0
    ;;
  right|left|above|below)
    [[ $# -ge 2 ]] || { usage; exit 2; }
    output="$2"
    coordinate="${3:-1920}"
    niri msg output eDP-1 on
    niri msg output "$output" on
    niri msg output eDP-1 scale 1.1
    niri msg output "$output" scale 1.0
    case "$1" in
      right)
        niri msg output eDP-1 position set 0 0
        niri msg output "$output" position set "$coordinate" 0
        ;;
      left)
        niri msg output "$output" position set 0 0
        niri msg output eDP-1 position set "$coordinate" 0
        ;;
      above)
        niri msg output "$output" position set 0 0
        niri msg output eDP-1 position set 0 "$coordinate"
        ;;
      below)
        niri msg output eDP-1 position set 0 0
        niri msg output "$output" position set 0 "$coordinate"
        ;;
    esac
    ;;
  *)
    usage
    exit 2
    ;;
esac

