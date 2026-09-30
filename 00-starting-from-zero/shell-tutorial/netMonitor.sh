#!/usr/bin/env bash

# netmon.sh — Live network speed monitor (no bc/grep -P needed)
# Usage: ./netmon.sh [interface]

[[ -r /proc/net/dev ]] || { echo "/proc/net/dev not readable (Linux only)"; exit 1; }

# Interface: argument, else default route, else first non-loopback
IFACE=${1:-$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')}
if [[ -z "$IFACE" ]]; then
    IFACE=$(awk -F'[: ]+' 'NR>2 && $2!="lo" {print $2; exit}' /proc/net/dev)
fi

if [[ -z "$IFACE" ]] || ! grep -q "^[[:space:]]*${IFACE}:" /proc/net/dev; then
    echo "Usage: $0 [interface]"
    echo "Available: $(awk -F'[: ]+' 'NR>2 {printf "%s ", $2}' /proc/net/dev)"
    exit 1
fi

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; CYAN=$'\033[0;36m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
bar_width=40

read_bytes() {
    awk -v ifc="$IFACE" '{ sub(/:/, " ") } $1 == ifc { print $2, $10 }' /proc/net/dev
}

repeat() { local s="" i; for ((i = 0; i < $2; i++)); do s+="$1"; done; printf '%s' "$s"; }

draw_bar() {
    local value=$1 max=$2 color=$3
    local filled=$(( value * bar_width / max ))
    (( filled > bar_width )) && filled=$bar_width
    (( filled < 0 )) && filled=0
    printf '%s%s%s%s%s' "$color" "$BOLD" "$(repeat '█' $filled)" "$(repeat '░' $((bar_width - filled)))" "$RESET"
}

fmt() {
    awk -v b="$1" 'BEGIN {
        if      (b >= 1073741824) printf "%.2f GB/s", b / 1073741824
        else if (b >= 1048576)    printf "%.2f MB/s", b / 1048576
        else if (b >= 1024)       printf "%.1f KB/s", b / 1024
        else                      printf "%d B/s", b
    }'
}

cleanup() { printf '\033[?25h\n'; exit 0; }
trap cleanup INT TERM

echo "${BOLD}${CYAN}NETMON${RESET} — Live Bandwidth Monitor (${IFACE})"
echo "Press ${YELLOW}Ctrl+C${RESET} to stop"
echo

printf '\033[?25l'   # hide cursor
peak_rx=1024; peak_tx=1024
read -r rx1 tx1 < <(read_bytes)

# Reserve two lines for the display
printf '\n\n'

while true; do
    sleep 1
    read -r rx2 tx2 < <(read_bytes)

    rx_speed=$(( rx2 - rx1 )); tx_speed=$(( tx2 - tx1 ))
    (( rx_speed < 0 )) && rx_speed=0
    (( tx_speed < 0 )) && tx_speed=0
    rx1=$rx2; tx1=$tx2

    (( rx_speed > peak_rx )) && peak_rx=$rx_speed
    (( tx_speed > peak_tx )) && peak_tx=$tx_speed

    printf '\033[2A'   # move up two lines and redraw
    printf '\r  %s↓ RX%s %s  %s%-12s%s\033[K\n' "$GREEN" "$RESET" "$(draw_bar $rx_speed $peak_rx "$GREEN")" "$GREEN" "$(fmt $rx_speed)" "$RESET"
    printf '\r  %s↑ TX%s %s  %s%-12s%s\033[K\n' "$RED" "$RESET" "$(draw_bar $tx_speed $peak_tx "$RED")" "$RED" "$(fmt $tx_speed)" "$RESET"
done
