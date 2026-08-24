#!/usr/bin/env bash
# ==============================================================================
# UNINSTALLER: AUTO-EXTRACT DOWNLOADS
# ==============================================================================

set -e

echo -e "\033[1;33m[*] Memulai proses uninstall Auto-Extract Downloads...\033[0m"

# 1. Hentikan dan matikan service systemd
echo -e "\033[1;34m[*] Menonaktifkan Systemd User Service...\033[0m"
systemctl --user disable --now auto-extract.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/auto-extract.service"
systemctl --user daemon-reload

# 2. Hapus file worker
echo -e "\033[1;34m[*] Menghapus script worker...\033[0m"
rm -f "$HOME/.local/bin/auto-extract-downloads.sh"

# 3. Hapus command saklar global
echo -e "\033[1;34m[*] Menghapus binary /usr/local/bin/auto-extract...\033[0m"
sudo rm -f /usr/local/bin/auto-extract

echo ""
echo -e "\033[1;32m======================================================================\033[0m"
echo -e "\033[1;32m  [SUCCESS] Auto-Extract Downloads berhasil dicopot tuntas!\033[0m"
echo -e "\033[1;32m======================================================================\033[0m"
