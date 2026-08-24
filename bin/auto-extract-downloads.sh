#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: AUTO-EXTRACT DOWNLOADS WORKER (RECURSIVE SUBFOLDER + FULL PROTECTION)
# LOKASI: ~/.local/bin/auto-extract-downloads.sh
# DIBUAT: 2026-08-25 untuk Cak Hizam (Node: hizam)
# ==============================================================================
# FUNGSI & LOGIKA KERJA:
# Mengawasi folder ~/Downloads BESERTA SELURUH SUBFOLDER (rekursif -r).
# Otomatis mengekstrak file .zip, .rar, .7z, .tar.gz di folder mana pun dalam Downloads.
#
# DAFTAR SEKRING PENGAMAN:
# 1. Sekring Anti-Muntah (Self-Compress Guard) -> Skip jika folder tujuan sudah ada & ada isinya.
# 2. Sekring Limit Ukuran (10 MB Guard) -> Skip jika file > 10 MB.
# 3. Sekring Multi-Part Archive -> Hanya trigger di part1, part 2/3/dst diskip.
# 4. Sekring Ruang Disk Kritis -> Batal ekstrak jika sisa storage < 1 GB.
# 5. Sekring Password Archive -> Skip file terenkripsi & notifikasi ekstrak manual.
# 6. Sekring Auto-Rollback -> Hapus folder kosong jika file korup/gagal ekstrak.
# 7. Sekring Max Depth (Anti-Loop Rekursif) -> Maksimal 4 level subfolder dari Downloads.
# ==============================================================================

WATCH_DIR="$HOME/Downloads"
MAX_SIZE_BYTES=10485760 # 10 MB
MIN_DISK_FREE_GB=1      # Minimal sisa storage 1 GB
MAX_DEPTH=4             # Maksimal kedalaman subfolder

mkdir -p "$WATCH_DIR"

# Parameter -r mengaktifkan pengawasan rekursif ke seluruh anak folder
inotifywait -r -m -e close_write,moved_to --format '%w%f' "$WATCH_DIR" 2>/dev/null | while read -r filepath; do
    # Abaikan jika file sudah tidak ada
    [ -f "$filepath" ] || continue

    filename=$(basename "$filepath")
    parent_dir=$(dirname "$filepath")
    lower_filename="${filename,,}"
    
    # Abaikan file parsial/sementara
    if [[ "$lower_filename" == *.crdownload || "$lower_filename" == *.tmp || "$lower_filename" == *.part || "$lower_filename" == *.~tmp || "$lower_filename" == .*.swp ]]; then
        continue
    fi

    # SEKRING 7: Batasi kedalaman subfolder agar tidak looping tak berhingga
    rel_path="${parent_dir#$WATCH_DIR}"
    depth=$(awk -F/ '{print NF-1}' <<< "$rel_path")
    if [ "$depth" -gt "$MAX_DEPTH" ]; then
        continue
    fi

    # SEKRING 3: Abaikan multi-part lanjutan
    if [[ "$lower_filename" =~ \.part0*[2-9][0-9]*\.rar$ ||           "$lower_filename" =~ \.r[0-9]{2,}$ ||           "$lower_filename" =~ \.z[0-9]{2,}$ ||           "$lower_filename" =~ \.(7z|zip)\.0*[2-9][0-9]*$ ||           "$lower_filename" =~ \.0*[2-9][0-9]*$ ]]; then
        continue
    fi
    
    # Deteksi format arsip
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

    if [ "$is_archive" = true ]; then
        # Ekstrak tepat di folder tempat file tersebut berada
        target_dir="$parent_dir/$base_name"
        
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
            rm -rf "$target_dir"
            notify-send -a "Auto Extract" -i dialog-error "Auto Extract Gagal" "File $filename korup atau tidak dapat diekstrak." 2>/dev/null
        fi
    fi
done
