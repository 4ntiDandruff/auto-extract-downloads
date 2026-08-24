<div align="center">

# ⚡ Auto-Extract Downloads for Linux Desktop
### *Sistem Otomatisasi Ekstraksi Arsip Terisolasi, Event-Driven & 9-Lapis Sekring Proteksi*

[![OS - Linux](https://img.shields.io/badge/OS-Linux%20(KDE%20%7C%20GNOME%20%7C%20XFCE)-blue?style=for-the-badge&logo=linux&logoColor=white)](https://kernel.org)
[![Desktop - KDE Plasma 6](https://img.shields.io/badge/Desktop-KDE%20Plasma%206%20%7C%20Wayland-1d99f3?style=for-the-badge&logo=kde&logoColor=white)](https://kde.org)
[![Core - Bash POSIX](https://img.shields.io/badge/Engine-POSIX%20Bash%20%2B%20inotify-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Process - Systemd](https://img.shields.io/badge/Daemon-Systemd%20User%20Unit-CC2200?style=for-the-badge&logo=systemd&logoColor=white)](https://systemd.io)
[![Version - v1.2.0](https://img.shields.io/badge/Release-v1.2.0%20Stable-success?style=for-the-badge)](https://github.com/4ntiDandruff/auto-extract-downloads)

<p align="center">
  <b>Solusi instan untuk mengatasi friksi dialog <i>Import / Open File</i> pada Linux Desktop.</b><br>
  <i>0% Polling CPU • Zero Background Memory Pressure • 9 Lapis Sekring Anti-Peluru</i>
</p>

---

</div>

## 1. Penjelasan Lengkap & Latar Belakang

Pada lingkungan Linux Desktop (KDE Plasma, GNOME, XFCE), jendela dialog pemilihan file (*File Picker / `KFileDialog`*) sengaja diisolasi demi keamanan proses induk. Akibatnya, saat teknisi atau pengguna ingin mengimpor berkas dari browser atau aplikasi kerja, tidak tersedia menu klik-kanan *"Extract Here"* di dalam dialog. Pengguna terpaksa berpindah jendela, membuka pengelola arsip manual (`Ark` / `File Roller`), mengekstrak berkas, lalu kembali ke dialog.

**Auto-Extract Downloads** memecahkan masalah tersebut pada tingkat fondasi sistem. Menggunakan arsitektur *event-driven* berbasis *kernel interrupt* (`inotify`), sistem secara otomatis memantau folder `~/Downloads` beserta seluruh subfoldernya secara rekursif. File arsip murni (`.zip`, `.rar`, `.7z`, `.tar.gz`, `.tar.xz`, `.tgz`) yang selesai diunduh akan langsung dibongkar ke dalam subfolder lokal dalam hitungan milidetik.

---

## 2. Treeview Direktori Proyek

```text
auto-extract-downloads/
├── bin/
│   ├── auto-extract               # Utilitas saklar CLI global (/usr/local/bin/auto-extract)
│   └── auto-extract-downloads.sh  # Worker engine inotify + parser 9 sekring pengaman
├── systemd/
│   └── auto-extract.service       # Unit service systemd user-level (auto-restart 3s)
├── .gitignore                     # Filter berkas build sementara, swap, dan log
├── install.sh                     # Installer multi-distro otomatis 1-klik (APT/Pacman/DNF)
├── uninstall.sh                   # Script pencopotan bersih tuntas tanpa residu
└── README.md                      # Dokumentasi teknis baku & panduan operasional
```

---

## 3. Tech Stack & Arsitektur Sistem

| Lapisan Sistem | Komponen / Library | Peran & Tanggung Jawab Arsitektur |
|---|---|---|
| **Kernel Event Layer** | `inotify-tools` (`inotifywait`) | Menerima sinyal hardware interrupt (`IN_CLOSE_WRITE`, `IN_MOVED_TO`) tanpa CPU polling |
| **Worker Engine** | POSIX Bash Script | Logika parsing ekstensi, kedalaman direktori, evaluasi 9 sekring, & triggering |
| **Archive Backend** | `unar` (The Unarchiver) & `7z` | Ekstraksi multi-format universal & deteksi otomatis arsip terenkripsi sandi |
| **Process Manager** | Systemd User Unit (`systemd --user`) | Manajemen daemons, auto-start sesi login, & isolasi resource user slice |
| **Desktop Alerting** | `libnotify` (`notify-send`) | Notifikasi visual asinkron non-blocking pada panel tray desktop environment |
| **Dynamic CLI Switch** | `/usr/local/bin/auto-extract` | Antarmuka pengguna untuk konfigurasi dinamis (`limit`, `depth`, `on/off`, `--help`) |

---

## 4. Diagram Alur & Topologi Sirkuit

```text
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                 USER WORKSPACE                                   │
│  [ Chrome / Brave / Firefox ] • [ FDM ] • [ Telegram ] • [ Wget / Curl ] • [ CLI ]
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │  Menulis data unduhan
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                        DIREKTORI ~/Downloads/ & SUBFOLDER                        │
│                    Trigger Event: IN_CLOSE_WRITE / IN_MOVED_TO                   │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │  Kernel Interrupt Pulsa (CPU: 0.0%)
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                 WORKER ENGINE (bin/auto-extract-downloads.sh)                    │
│                                                                                  │
│   ├── [Sekring 1: Anti-Muntah] ─────► (Skip jika folder tujuan sudah ada isinya) │
│   ├── [Sekring 2: Limit Ukuran] ────► (Skip jika ukuran arsip > MAX_SIZE_MB)     │
│   ├── [Sekring 3: Multi-Part] ──────► (Hanya trigger part1, abaikan part2..N)    │
│   ├── [Sekring 4: Disk Check] ──────► (Batal jika sisa storage partisi < 1 GB)   │
│   ├── [Sekring 5: Password Guard] ──► (Deteksi enkripsi -> minta ekstrak manual) │
│   ├── [Sekring 6: Auto-Rollback] ───► (Bersihkan folder jika arsip korup/gagal)  │
│   ├── [Sekring 7: Max Depth] ───────► (Batasi kedalaman subfolder maks N level)  │
│   ├── [Sekring 8: Dev Exclude] ─────► (Abaikan .git/, node_modules/, .cache/)    │
│   └── [Sekring 9: Image Guard] ─────► (Proteksi ISO, BIN, ROM, VDI, Docker TAR)  │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │  Hasil Ekstraksi (Selesai / Skip / Gagal)
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                            OUTPUT AKHIR & NOTIFIKASI                             │
│   • Subfolder Baru: ~/Downloads/.../<nama-arsip>/                                │
│   • Pop-up Desktop: "Auto Extract Selesai" via KDE Notification Center           │
│   • File Dialog: Berkas langsung matang siap di-import tanpa proses manual       │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Filosofi Build & Dependensi Minimal

- **Zero-Compilation (No-Build Step)**: Mengeliminasi runtime overhead (Node.js/Python/Rust compiler) di tingkat background. Murni berjalan di atas POSIX shell standar.
- **Konsumsi Daya & CPU 0.0% (Zero Idle Polling)**: Menggunakan mekanisme *Linux Inotify Subsystem*, proses tidur (*sleep/idle*) total dan hanya aktif saat ada pulsa event dari kernel.
- **Footprint Memori Ultra Ringan**: Berjalan pada `user.slice` dengan alokasi RAM hanya **~1.0 MB – 1.9 MB** (jauh lebih hemat dibanding GUI Archive Manager ~100 MB).
- **Multi-Distro Packaging**: Mendukung instalasi otomatis lintas distro Linux utama (`apt-get`, `pacman`, `dnf`).

---

## 6. Sorotan Versi Terkini (v1.2.0 Stable)

- 📁 **Recursive Subfolder Monitoring (`-r`)**: Memantau seluruh anak folder unduhan secara dinamis.
- 🛡️ **Implementasi 9 Lapis Sekring Proteksi (Safety Fuses)**:
  1. `Anti-Muntah`: Mencegah loop rekursif saat user mengompresi folder lokal sendiri.
  2. `Dynamic Limit Ukuran`: Mencegah lag sistem saat mengunduh arsip besar (Default: 10 MB).
  3. `Multi-Part Guard`: Filter cerdas untuk `.part1.rar`, `.part01.rar`, `.001`.
  4. `Disk Undervoltage Protection`: Batal otomatis jika sisa ruang partisi < 1 GB.
  5. `Password Guard`: Deteksi header terenkripsi via `lsar`/`7z` tanpa menahan proses background.
  6. `Auto-Rollback`: Menghapus folder kosong jika file arsip terbukti korup atau tidak lengkap.
  7. `Max Depth Guard`: Pembatas kedalaman traversal subfolder (Default: 4 Level).
  8. `Exclude Dev & Hidden Folders`: Mengabaikan folder `.git/`, `node_modules/`, `.cache/`, `.venv/`, `.local/`.
  9. `Image & Container Protection`: Proteksi mutlak file `.iso`, `.bin`, `.rom`, `.img`, `.vdi`, `.qcow2`, `.vmdk`, `.vhdx`, `.vhd`, `.oci`, `.tar` (Docker/Podman image), `.sif`, `.AppImage`, `.flatpak`, `.snap`, `.deb`.
- 🎛️ **Dynamic CLI Configuration (Fase 2)**: Pengaturan sekring langsung via command terminal tanpa bongkar file script (`auto-extract limit <MB>` & `auto-extract depth <N>`).

---

## 7. Tabel Valuasi & Efisiensi Biaya Operasional

| Indikator Evaluasi | Metode Manual Konvensional | Dengan Auto-Extract Downloads | Penghematan & Nilai Tambah |
|---|---|---|---|
| **Waktu Ekstraksi per File** | 10 – 20 detik (Buka GUI, cari direktori, ekstrak) | **< 0.5 detik (Instan Latar Belakang)** | Efisiensi waktu proses hingga **97%** |
| **Friksi Dialog Import** | Pindah window → ekstrak manual → kembali ke dialog | File langsung matang siap dipilih di dialog | Menghilangkan *context-switching fatigue* |
| **Konsumsi RAM Desktop** | GUI Archive Manager (~80 MB – 150 MB RAM) | Background Worker (**~1.5 MB RAM**) | Penghematan alokasi RAM hingga **98%** |
| **Valuasi Waktu Teknisi** | 15x unduhan/hari = ~2.5 jam terbuang/bulan | Eksekusi instan tanpa campur tangan user | **Menghemat ~30 jam waktu produktif/tahun** |

---

## 8. Roadmap & Rencana Pengembangan

| Tahapan Rilis | Target Fitur & Skalabilitas | Nilai Tambah bagi Pengguna |
|---|---|---|
| **Fase 1 (v1.0.0)** | 6 Sekring Proteksi Dasar + Systemd Unit + CLI Switch | Stabilitas pondasi & integrasi desktop dasar |
| **Fase 2 (v1.2.0 - Aktif)** | Rekursif Subfolder + 9 Sekring Proteksi + Dynamic CLI Config | Fleksibilitas penuh & proteksi komprehensif |
| **Fase 3 (Berikutnya)** | KDE Plasma System Tray Toggle / KRunner Runner Plugin | Pengendalian visual interaktif via GUI desktop |
| **Fase 4** | Auto-Decrypt Vault berbasis kamus/wordlist lokal | Ekstraksi otomatis arsip berpassword langganan |

---

## 9. Panduan Operasional & Verifikasi (Smoke Test)

### A. Pemasangan Cepat (1-Klik)
```bash
git clone https://github.com/4ntiDandruff/auto-extract-downloads.git
cd auto-extract-downloads
chmod +x install.sh uninstall.sh
./install.sh
```

### B. Perintah Saklar CLI Terminal
```bash
# Menampilkan panduan bantuan & konfigurasi aktif
auto-extract --help

# Memeriksa status service dan parameter sekring
auto-extract status

# Mengubah batas ukuran file secara dinamis (contoh: 50 MB)
auto-extract limit 50

# Mengubah batas kedalaman subfolder (contoh: 3 level)
auto-extract depth 3

# Menyalakan / Mematikan sensor sementara
auto-extract off
auto-extract on
```

### C. Verifikasi Pengujian Runtime (Smoke Test)
```bash
# 1. Masuk ke direktori Downloads
cd ~/Downloads

# 2. Buat file arsip uji coba
echo "Verifikasi Auto Extract" > test_dummy.txt
7z a -tzip test_dummy.zip test_dummy.txt >/dev/null
rm -f test_dummy.txt

# 3. Verifikasi folder hasil ekstraksi instan:
ls -la ~/Downloads/test_dummy/

# 4. Bersihkan file uji coba
rm -rf ~/Downloads/test_dummy ~/Downloads/test_dummy.zip
```

### D. Pencopotan Tuntas (Uninstall)
```bash
./uninstall.sh
```

---

<div align="center">

*Dibuat & dioptimalkan untuk performa desktop Linux profesional.*  
**Megapass Intra Solusindo • Sidoarjo, Indonesia**

</div>
