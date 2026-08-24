#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: AUTO-EXTRACT DOWNLOADS WORKER (FULL CIRCUIT PROTECTION)
# LOKASI: ~/.local/bin/auto-extract-downloads.sh
# DIBUAT: 2026-08-25 untuk Cak Hizam (Node: hizam)
# ==============================================================================
# FUNGSI & LOGIKA KERJA:
# Mengawasi folder ~/Downloads via kernel interrupt inotify (0% CPU idle).
# Otomatis mengekstrak file .zip, .rar, .7z, .tar.gz begitu selesai didownload.
#
# DAFTAR 6 SEKRING PENGAMAN (SAFETY FUSES):
# 1. Sekring Anti-Muntah (Self-Compress Guard):
#    - Jika folder sudah ada & berisi, proses ekstrak diskip (mencegah loop saat kompres sendiri).
# 2. Sekring Limit Ukuran (10 MB Guard):
#    - File > 10 MB tidak diekstrak otomatis agar hemat resource dan tidak bikin lag.
# 3. Sekring Multi-Part Archive:
#    - Hanya trigger pada .part1 / .001. Part lanjutan (.part2, .part3, dst) otomatis diskip.
# 4. Sekring Ruang Disk Kritis (Low Storage Protection):
#    - Jika sisa storage partisi < 1 GB, ekstrak otomatis dibatalkan demi keamanan OS.
# 5. Sekring Password Archive (Encrypted Guard):
#    - File arsip berpassword dideteksi via lsar/7z, diskip, dan diberi notifikasi ekstrak manual.
# 6. Sekring Rollback Folder Gagal (Clean-Break on Error):
#    - Jika ekstrak gagal / file korup, folder kosong yang terlanjur dibuat langsung dihapus bersih.
#
# CARA KONTROL SAKLAR CEPAT:
#   auto-extract status -> Cek status apakah sensor aktif
#   auto-extract off    -> Matikan sementara
#   auto-extract on     -> Hidupkan kembali
# ==============================================================================

WATCH_DIR="$HOME/Downloads"
MAX_SIZE_BYTES=10485760 # Batas maksimum 10 MB (10 * 1024 * 1024 bytes)
MIN_DISK_FREE_GB=1      # Minimal sisa storage 1 GB

mkdir -p "$WATCH_DIR"

inotifywait -m -e close_write,moved_to --format '%w%f' "$WATCH_DIR" | while read -r filepath; do
    filename=$(basename "$filepath")
    lower_filename="${filename,,}"
    
    # Abaikan file parsial/sementara browser/downloader/kompresor
    if [[ "$lower_filename" == *.crdownload || "$lower_filename" == *.tmp || "$lower_filename" == *.part || "$lower_filename" == *.~tmp || "$lower_filename" == .*.swp ]]; then
        continue
    fi

    # SEKRING 3: Abaikan multi-part lanjutan (part 2, 3, dst)
    if [[ "$lower_filename" =~ \.part0*[2-9][0-9]*\.rar$ ||           "$lower_filename" =~ \.r[0-9]{2,}$ ||           "$lower_filename" =~ \.z[0-9]{2,}$ ||           "$lower_filename" =~ \.(7z|zip)\.0*[2-9][0-9]*$ ||           "$lower_filename" =~ \.0*[2-9][0-9]*$ ]]; then
        continue
    fi
    
    # Deteksi ekstensi arsip
    is_archive=false
    base_name=""

    if [[ "$lower_filename" =~ ^(.*)\.part0*1\.rar$ ]]; then
        is_archive=true
        base_name="${BASH_REMATCH[1]}"
    elif [[ "$lower_filename" =~ ^(.*)\.(7z|zip)\.0*1$ ]]; then
        is_archive=true
        base_name="${BASH_REMATCH[1]}"
    elif [[ "$lower_filename" == *.tar.gz || "$lower_filename" == *.tar.xz || "$lower_filename" == *.tgz ]]; then
        is_archive=true
        base_name="${filename%.*}"
        base_name="${base_name%.*}"
    elif [[ "$lower_filename" == *.zip || "$lower_filename" == *.rar || "$lower_filename" == *.7z ]]; then
        is_archive=true
        base_name="${filename%.*}"
    fi

    if [ "$is_archive" = true ] && [ -f "$filepath" ]; then
        target_dir="$WATCH_DIR/$base_name"
        
        # SEKRING 1: Anti-Muntah
        if [ -d "$target_dir" ] && [ "$(ls -A "$target_dir" 2>/dev/null)" ]; then
            continue
        fi
        
        # SEKRING 2: Limit Ukuran File 10 MB
        filesize=$(stat -c%s "$filepath" 2>/dev/null || echo 0)
        if [ "$filesize" -gt "$MAX_SIZE_BYTES" ]; then
            notify-send -a "Auto Extract" -i dialog-information "Auto Extract Dilewati (> 10 MB)" "$filename berukuran > 10 MB. Ekstrak manual jika diperlukan." 2>/dev/null
            continue
        fi

        # SEKRING 4: Proteksi Ruang Disk Kritis (< 1 GB)
        avail_gb=$(df -BG "$WATCH_DIR" | awk 'NR==2 {print $4}' | tr -d 'G')
        if [ "${avail_gb:-0}" -lt "$MIN_DISK_FREE_GB" ]; then
            notify-send -a "Auto Extract" -i dialog-warning "Auto Extract Dibatalkan" "Sisa ruang disk kritis (< 1 GB). Kosongkan disk terlebih dahulu." 2>/dev/null
            continue
        fi

        # SEKRING 5: Proteksi Arsip Berpassword
        # lsar / 7z cek proteksi enkripsi header/data
        if lsar "$filepath" 2>&1 | grep -iq "password" || 7z l -slt "$filepath" 2>&1 | grep -iq "Encrypted = +"; then
            notify-send -a "Auto Extract" -i dialog-password "Arsip Terkunci Password" "$filename butuh password. Silakan ekstrak manual melalui Ark / Dolphin." 2>/dev/null
            continue
        fi
        
        # Eksekusi ekstraksi
        mkdir -p "$target_dir"
        unar -quiet -no-directory -output-directory "$target_dir" "$filepath" 2>/dev/null
        exit_code=$?

        # SEKRING 6: Rollback Folder Kosong jika Gagal/Korup
        if [ $exit_code -eq 0 ] && [ "$(ls -A "$target_dir" 2>/dev/null)" ]; then
            notify-send -a "Auto Extract" -i package-x-generic "Auto Extract Selesai" "$filename berhasil diekstrak ke: $base_name" 2>/dev/null
        else
            # Bersihkan folder jika proses ekstrak gagal / file korup
            rm -rf "$target_dir"
            notify-send -a "Auto Extract" -i dialog-error "Auto Extract Gagal" "File $filename korup atau tidak dapat diekstrak." 2>/dev/null
        fi
    fi
done
