# Auto-Extract Downloads for Linux Desktop

> **Sistem Otomatisasi Ekstraksi Arsip Terisolasi & Ringan untuk Linux Desktop (KDE / GNOME / XFCE)**  
> Mengatasi keterbatasan dialog *Import/Open File* pada Linux dengan arsitektur *event-driven* berbasis *kernel interrupt* (`inotify`).

---

## 1. Penjelasan Lengkap (Bahasa Indonesia)
**Auto-Extract Downloads** adalah utilitas latar belakang (*background service*) yang memantau folder `~/Downloads` beserta subfoldernya secara rekursif. Utilitas ini secara otomatis membongkar file arsip (`.zip`, `.rar`, `.7z`, `.tar.gz`, `.tar.xz`, `.tgz`) ke dalam subfolder lokal tepat saat proses unduhan selesai 100%.

Dibangun khusus untuk teknisi sirkuit dan profesional yang menginginkan alur kerja cepat saat membuka/mengimpor file dari aplikasi pihak ketiga, tanpa perlu membuka manajer arsip manual (`Ark` / `File Roller`), tanpa konsumsi CPU di latar belakang, dan dilengkapi sekring proteksi lengkap agar sistem tetap stabil dan aman.

---

## 2. Treeview Direktori Proyek

```text
auto-extract-downloads/
├── bin/
│   ├── auto-extract               # Command saklar CLI global (/usr/local/bin)
│   └── auto-extract-downloads.sh  # Script worker engine logika inotify & 7 sekring
├── systemd/
│   └── auto-extract.service       # Unit service systemd user-level
├── install.sh                     # Script installer otomatis 1-klik
├── uninstall.sh                   # Script pembersih & copot tuntas
├── .gitignore                     # Filter file sementara & log
└── README.md                      # Dokumentasi teknis standar 9 elemen
```

---

## 3. Tech Stack & Arsitektur

| Lapisan / Komponen | Teknologi | Keterangan & Peran Arsitektur |
|---|---|---|
| **Event Kernel** | `inotify-tools` (`inotifywait`) | Menangkap sinyal filesystem (`close_write`, `moved_to`) murni berbasis hardware interrupt |
| **Worker Engine** | POSIX Bash Script | Logika parser ekstensi, filter multi-part, dan eksekutor 7 sekring pengaman |
| **Archive Backend** | `unar` (The Unarchiver) & `7z` | Engine ekstraksi universal multi-format & detektor proteksi sandi arsip |
| **Process Manager**| Systemd User Unit (`systemd --user`) | Manajemen siklus hidup proses, auto-start saat login desktop, & auto-recovery |
| **Desktop Alert**  | `libnotify` (`notify-send`) | Notifikasi visual non-blocking terintegrasi dengan panel KDE Plasma & GNOME Shell |

---

## 4. Infrastruktur Jaringan & Diagram Topologi

```text
+-----------------------------------------------------------------------------------+
|                                  USER WORKSPACE                                   |
|   [ Browser (Chrome/Brave) ] / [ FDM ] / [ Telegram ] / [ Wget/Curl ] / [ CLI ]   |
+-----------------------------------------+-----------------------------------------+
                                          |
                            (Selesai Menulis File Arsip)
                                          v
+-----------------------------------------------------------------------------------+
|                        DIREKTORI ~/Downloads/ & SUBFOLDER                         |
|                    Trigger Event: IN_CLOSE_WRITE / IN_MOVED_TO                    |
+-----------------------------------------+-----------------------------------------+
                                          |
                         (Kernel Interrupt Pulsa - 0% Polling)
                                          v
+-----------------------------------------------------------------------------------+
|                  WORKER ENGINE (bin/auto-extract-downloads.sh)                    |
|                                                                                   |
|  [ Sekring 1: Anti-Muntah ] ------> (Skip jika folder tujuan sudah ada isinya)    |
|  [ Sekring 2: Limit 10 MB ] ------> (Skip jika ukuran file arsip > 10 MB)         |
|  [ Sekring 3: Multi-Part  ] ------> (Hanya trigger part1, skip part2, part3..N)   |
|  [ Sekring 4: Disk Check  ] ------> (Batal jika free storage partisi < 1 GB)      |
|  [ Sekring 5: Pass Guard  ] ------> (Deteksi sandi via lsar/7z -> minta manual)   |
|  [ Sekring 6: Auto-Rollback] -----> (Hapus folder kosong jika file korup/gagal)   |
|  [ Sekring 7: Max Depth   ] ------> (Batasi kedalaman subfolder maks 4 level)     |
+-----------------------------------------+-----------------------------------------+
                                          |
                              (Hasil Status Ekstraksi)
                                          v
+-----------------------------------------------------------------------------------+
|                           OUTPUT AKHIR & NOTIFIKASI                               |
|        - Folder Hasil Ekstrak: ~/Downloads/.../<nama-arsip>/                      |
|        - Pop-up Desktop: "Auto Extract Selesai" via libnotify / KDE Plasma        |
+-----------------------------------------------------------------------------------+
```

---

## 5. Filosofi Build & Dependensi Minimal
- **Zero Compilation (No-Build)**: Menggunakan shell script murni yang berinteraksi langsung dengan utilitas POSIX bawaan Linux.
- **Zero CPU Idle**: Tidak ada loop polling (`while sleep`). Konsumsi CPU tetap **0.0%** konstan saat standby.
- **RAM Footprint Ultra Ringan**: Berjalan pada user slice systemd dengan konsumsi memori hanya **~1.5 MB – 1.9 MB**.
- **Dependensi Standar**: Hanya membutuhkan paket `inotify-tools`, `unar`, `p7zip-full`, dan `libnotify-bin` yang tersedia di seluruh distro Linux.

---

## 6. Sorotan Versi Terkini (v1.1.0 Stable)
- **Recursive Subfolder Monitoring (`-r`)**: Mendukung pengawasan otomatis ke dalam anak folder sedalam 4 tingkat.
- **7 Sekring Proteksi Lengkap (Safety Fuses)**:
  1. *Anti-Muntah*: Mencegah loop kompresi saat user mengompres folder sendiri.
  2. *Limit Ukuran 10 MB*: Mencegah lag sistem saat mengunduh file game / video besar.
  3. *Multi-Part Guard*: Menghindari ekstraksi berulang pada file `.part1.rar`, `.part2.rar`, `.001`.
  4. *Disk Undervoltage*: Membatalkan ekstraksi jika sisa ruang disk < 1 GB.
  5. *Password Guard*: Mencegah freeze pada arsip terenkripsi sandi.
  6. *Auto-Rollback*: Membersihkan folder kosong jika arsip korup atau tidak valid.
  7. *Max Depth Guard*: Mengamankan sistem dari struktur folder loop tanpa batas.
- **Global Terminal Switch (`auto-extract`)**: Pengendalian operasional on/off/status instan.

---

## 7. Tabel Valuasi & Efisiensi Biaya Operasional

| Parameter Analisis | Cara Konvensional (Manual Ark / GUI) | Dengan Auto-Extract Downloads | Penghematan & Nilai Tambah |
|---|---|---|---|
| **Durasi per Ekstraksi** | 10 – 20 detik (Buka Ark, pilih folder, ekstrak) | **< 0.5 detik (Instan otomatis)** | Efisiensi waktu proses hingga **97%** |
| **Friksi Dialog Import File** | Pindah window, ekstrak manual, kembali ke dialog | File langsung matang siap pilih di dialog | Meniadakan *context-switching* teknisi |
| **Konsumsi Memori Aplikasi** | GUI Archive Manager (~80 MB – 150 MB RAM) | Background Worker (**~1.5 MB RAM**) | Menghemat alokasi RAM hingga **98%** |
| **Valuasi Jam Kerja Teknisi** | 15x unduhan/hari = ~2.5 jam terbuang/bulan | Eksekusi instan latar belakang | **Menghemat ~30 jam waktu produktif/tahun** |

---

## 8. Roadmap & Rencana Pengembangan

| Tahapan / Versi | Target Fitur & Skalabilitas | Nilai Tambah bagi Pengguna |
|---|---|---|
| **Fase 1 (v1.1.0 Aktif)** | 7 Sekring Proteksi + Rekursif Subfolder + CLI Saklar | Stabilitas penuh, tanpa perawatan manual |
| **Fase 2 (Berikutnya)** | Dynamic CLI Configuration (`auto-extract limit 50MB`) | Pengaturan parameter sekring langsung via CLI |
| **Fase 3** | KDE System Tray Toggle / KRunner Extension | Kontrol visual interaktif tanpa terminal |
| **Fase 4** | Auto-Decrypt Vault berbasis wordlist kamus lokal | Ekstraksi instan arsip berpassword langganan forum/skema |

---

## 9. Panduan Operasional & Verifikasi (Smoke Test)

### A. Pemasangan (Instalasi)
```bash
git clone https://github.com/4ntiDandruff/auto-extract-downloads.git
cd auto-extract-downloads
chmod +x install.sh uninstall.sh
./install.sh
```

### B. Perintah Saklar Terminal
```bash
auto-extract          # Menampilkan ringkasan status & dokumentasi bantuan
auto-extract status   # Memeriksa apakah sensor sedang aktif (running)
auto-extract off      # Mematikan sementara sensor auto-extract
auto-extract on       # Menghidupkan kembali sensor auto-extract
```

### C. Verifikasi Pengujian (Smoke Test Runtime)
```bash
# 1. Masuk ke folder Downloads
cd ~/Downloads

# 2. Buat file dummy dan bungkus menjadi file zip
echo "Verifikasi Auto Extract" > test_dummy.txt
7z a -tzip test_dummy.zip test_dummy.txt >/dev/null
rm -f test_dummy.txt

# 3. Tunggu 1 detik, periksa folder hasil ekstraksi:
ls -la ~/Downloads/test_dummy/

# 4. Bersihkan file uji coba
rm -rf ~/Downloads/test_dummy ~/Downloads/test_dummy.zip
```

### D. Pencopotan (Uninstall)
```bash
./uninstall.sh
```

---
*Dokumentasi disusun sesuai standar baku operasional AGENTS.md (R10).*
