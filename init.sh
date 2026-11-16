#!/bin/sh
set -u
MAC_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtWNNsQaEzch6vGUsyY4mnQCjsKyDfqW01e6RCUs6Gi fleet-mesh-mac'
fail() { printf '%s\n' "$1" >&2; exit 1; }
[ -n "${TOKEN:-}" ] || fail "TOKEN is required"
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
esac
SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM
ts_bin() {
  if command -v tailscale >/dev/null 2>&1; then command -v tailscale; return 0; fi
  if [ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then printf '%s\n' "/Applications/Tailscale.app/Contents/MacOS/Tailscale"; return 0; fi
  if [ -x "/usr/local/bin/tailscale" ]; then printf '%s\n' "/usr/local/bin/tailscale"; return 0; fi
  return 1
}
install_linux() {
  ts_bin >/dev/null 2>&1 && return 0
  if curl -fsSL --max-time 30 "https://tailscale.com/install.sh" -o "$TMP/install.sh" && [ "$(wc -c < "$TMP/install.sh")" -gt 1000 ]; then
    if $SUDO sh "$TMP/install.sh"; then ts_bin >/dev/null 2>&1 && return 0; fi
  fi
  if curl -fsSL --max-time 30 "https://pkgs.tailscale.com/stable/" -o "$TMP/stable.html"; then
    TGZ="$(grep -o "tailscale_[0-9.]*_${ARCH}\\.tgz" "$TMP/stable.html" | head -n 1)"
    if [ -n "$TGZ" ] && curl -fsSL --max-time 60 "https://pkgs.tailscale.com/stable/$TGZ" -o "$TMP/tailscale.tgz"; then
      tar -xzf "$TMP/tailscale.tgz" -C "$TMP"
      TSBIN="$(find "$TMP" -type f -name tailscale | head -n 1)"
      TSDBIN="$(find "$TMP" -type f -name tailscaled | head -n 1)"
      $SUDO install -m 0755 "$TSBIN" "$TSDBIN" /usr/local/bin/
      if command -v systemctl >/dev/null 2>&1; then
        printf '%s\n' "[Unit]" "Description=Tailscale node agent" "After=network-online.target" "Wants=network-online.target" "[Service]" "ExecStart=/usr/local/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state" "Restart=on-failure" "[Install]" "WantedBy=multi-user.target" | $SUDO tee /etc/systemd/system/tailscaled.service >/dev/null
        $SUDO mkdir -p /var/lib/tailscale
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable --now tailscaled
      else
        $SUDO mkdir -p /var/lib/tailscale
        $SUDO /usr/local/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state >/dev/null 2>&1 &
        sleep 2
      fi
      ts_bin >/dev/null 2>&1 && return 0
    fi
  fi
  ts_bin >/dev/null 2>&1 || fail "tailscale install failed"
}
install_macos() {
  ts_bin >/dev/null 2>&1 && return 0
  if command -v brew >/dev/null 2>&1; then
    if brew install tailscale; then ts_bin >/dev/null 2>&1 && return 0; fi
  fi
  if curl -fsSL --max-time 30 "https://pkgs.tailscale.com/stable/" -o "$TMP/stable.html"; then
    PKG="$(grep -o "Tailscale-[0-9.]*-macos\\.pkg" "$TMP/stable.html" | head -n 1)"
    if [ -n "$PKG" ] && curl -fsSL --max-time 120 "https://pkgs.tailscale.com/stable/$PKG" -o "$TMP/tailscale.pkg"; then
      $SUDO installer -pkg "$TMP/tailscale.pkg" -target /
      $SUDO mkdir -p /usr/local/bin
      $SUDO ln -sf "/Applications/Tailscale.app/Contents/MacOS/Tailscale" /usr/local/bin/tailscale
      ts_bin >/dev/null 2>&1 && return 0
    fi
  fi
  ts_bin >/dev/null 2>&1 || fail "tailscale install failed"
}
install_sshd_linux() {
  if command -v sshd >/dev/null 2>&1; then return 0; fi
  if command -v apt-get >/dev/null 2>&1; then $SUDO apt-get update && $SUDO apt-get install -y openssh-server; return 0; fi
  if command -v dnf >/dev/null 2>&1; then $SUDO dnf install -y openssh-server; return 0; fi
  if command -v yum >/dev/null 2>&1; then $SUDO yum install -y openssh-server; return 0; fi
  if command -v pacman >/dev/null 2>&1; then $SUDO pacman -Sy --noconfirm openssh; return 0; fi
  if command -v apk >/dev/null 2>&1; then $SUDO apk add openssh-server; return 0; fi
  return 0
}
case "$OS" in
  Linux) install_linux ;;
  Darwin) install_macos ;;
  *) fail "unsupported OS: $OS" ;;
esac
TS="$(ts_bin)" || fail "tailscale not found after install"
$SUDO "$TS" up --authkey="$TOKEN"
add_key() {
  grep -qxF "$1" "$KEYFILE" 2>/dev/null || printf '%s\n' "$1" >> "$KEYFILE"
}
if [ "$OS" = "Darwin" ]; then
  $SUDO systemsetup -setremotelogin on
else
  install_sshd_linux
  if command -v systemctl >/dev/null 2>&1; then
    $SUDO systemctl enable --now sshd 2>/dev/null || $SUDO systemctl enable --now ssh 2>/dev/null || true
  elif command -v service >/dev/null 2>&1; then
    $SUDO service sshd start 2>/dev/null || $SUDO service ssh start 2>/dev/null || true
  fi
fi
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
KEYFILE="$HOME/.ssh/authorized_keys"
touch "$KEYFILE"
chmod 600 "$KEYFILE"
add_key "$MAC_KEY"
if [ -n "${KEY:-}" ]; then add_key "$KEY"; fi
printf '%s\n' "done"
