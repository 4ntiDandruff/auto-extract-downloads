#!/usr/bin/env bash
# ==============================================================================
# INSTALLER: AUTO-EXTRACT DOWNLOADS
# Target: Ubuntu / Kubuntu / Debian / Linux Mint / Arch / Fedora
# ==============================================================================

set -e

echo -e "\033[1;34m[*] Memulai instalasi Auto-Extract Downloads...\033[0m"

# 1. Pastikan dependencies terpasang
echo -e "\033[1;34m[*] Memeriksa dependensi sistem...\033[0m"
if command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y inotify-tools unar p7zip-full libnotify-bin
fi

# 2. Pasang Script Worker
echo -e "\033[1;34m[*] Memasang Script Worker...\033[0m"
mkdir -p "$HOME/.local/bin"
cp bin/auto-extract-downloads.sh "$HOME/.local/bin/auto-extract-downloads.sh"
chmod +x "$HOME/.local/bin/auto-extract-downloads.sh"

# 3. Pasang Systemd User Service
echo -e "\033[1;34m[*] Mengonfigurasi Systemd User Unit...\033[0m"
mkdir -p "$HOME/.config/systemd/user"
cp systemd/auto-extract.service "$HOME/.config/systemd/user/auto-extract.service"

# 4. Pasang Command Saklar Global
echo -e "\033[1;34m[*] Memasang Command Global /usr/local/bin/auto-extract...\033[0m"
sudo cp bin/auto-extract /usr/local/bin/auto-extract
sudo chmod +x /usr/local/bin/auto-extract

# 5. Aktifkan Service
echo -e "\033[1;34m[*] Mengaktifkan dan menyalakan service...\033[0m"
systemctl --user daemon-reload
systemctl --user enable --now auto-extract.service

echo ""
echo -e "\033[1;32m======================================================================\033[0m"
echo -e "\033[1;32m  [SUCCESS] Auto-Extract Downloads Berhasil Terpasang & Aktif!\033[0m"
echo -e "\033[1;32m======================================================================\033[0m"
echo "Ketik 'auto-extract' di terminal untuk melihat status & panduan penggunaan."
