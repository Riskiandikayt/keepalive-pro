# 🌐 Keepalive – Website Monitor 24/7 untuk Termux Android

Script bash ringan untuk menjaga website tetap aktif, memonitor status, dan auto-reload browser secara otomatis di Android via Termux.

---

## 📋 Fitur

| Fitur | Keterangan |
|---|---|
| Auto Ping | Kirim request GET/HEAD ke website setiap interval |
| Auto Browser Reload | Buka & reload Chrome/browser otomatis |
| Monitoring Status | HTTP status code + response time |
| Auto Retry Internet | Tunggu & lanjut otomatis saat internet kembali |
| Logging | Simpan log ke `logs.txt` |
| Dashboard Terminal | Tampilan status real-time di terminal |
| Auto Restart | Restart otomatis jika script crash |
| Notifikasi Android | Notif saat website offline/online & internet putus |
| Multi Website | Monitor banyak website sekaligus |
| Config File | Semua pengaturan di `config.sh` |

---

## 📦 Cara Install di Termux

### 1. Install Termux
Download Termux dari **F-Droid** (bukan Play Store):
> https://f-droid.org/packages/com.termux/

### 2. Install Dependensi

Buka Termux dan jalankan:

```bash
pkg update && pkg upgrade -y
pkg install curl bash termux-api -y
```

> `termux-api` diperlukan untuk fitur notifikasi Android.
> Pastikan juga install **Termux:API** dari F-Droid.

### 3. Download / Salin Script

**Opsi A – Clone dari repo (jika ada):**
```bash
git clone https://github.com/username/keepalive.git
cd keepalive
```

**Opsi B – Salin manual:**
Buat folder dan salin semua file ke dalamnya:
```bash
mkdir ~/keepalive && cd ~/keepalive
```
Salin file: `main.sh`, `start.sh`, `stop.sh`, `restart.sh`, `status.sh`, `config.sh`

### 4. Beri Izin Eksekusi

```bash
chmod +x ~/keepalive/*.sh
```

### 5. Izinkan Notifikasi (opsional)
Di Android, buka **Termux:API** → pastikan izin notifikasi diaktifkan.

---

## ⚙️ Cara Ganti URL Website

Edit file `config.sh`:

```bash
nano ~/keepalive/config.sh
```

Cari bagian `WEBSITES` dan ubah:

```bash
WEBSITES=(
    "https://website-kamu.com"
    "https://website-kedua.com"
)
```

Simpan dengan `Ctrl+O` → `Enter` → `Ctrl+X`.

---

## 🔧 Konfigurasi Lengkap (`config.sh`)

```bash
# Daftar website yang dimonitor
WEBSITES=("https://example.com")

# Interval ping dalam detik
REFRESH_INTERVAL=60

# Timeout request curl (detik)
REQUEST_TIMEOUT=10

# Metode request: GET atau HEAD
REQUEST_METHOD="GET"

# Aktifkan/nonaktifkan fitur (true/false)
ENABLE_BROWSER=true
ENABLE_LOG=true
ENABLE_NOTIFICATION=true
ENABLE_DASHBOARD=true
```

---

## ▶️ Cara Menjalankan

### Jalankan di foreground (lihat dashboard langsung):
```bash
cd ~/keepalive
bash main.sh
```

### Jalankan di background:
```bash
cd ~/keepalive
./start.sh
```

### Cek status:
```bash
./status.sh
```

### Stop script:
```bash
./stop.sh
```

### Restart script:
```bash
./restart.sh
```

---

## 🔄 Cara Jalan di Background (tetap aktif saat layar mati)

### Opsi 1 – Gunakan `start.sh`
```bash
./start.sh
```
Script berjalan di background dan auto-restart jika crash.

### Opsi 2 – Gunakan `screen`
```bash
pkg install screen
screen -S keepalive
bash main.sh
# Tekan Ctrl+A lalu D untuk detach (script tetap jalan)
# Untuk kembali: screen -r keepalive
```

### Opsi 3 – Gunakan `nohup`
```bash
nohup bash main.sh > ~/keepalive/nohup.log 2>&1 &
```

### Tips: Cegah Termux di-kill Android
- Aktifkan **"Disable Battery Optimization"** untuk Termux di Settings Android
- Atau pasang **Termux:Boot** (F-Droid) agar script otomatis jalan saat HP restart

---

## 📂 Struktur File

```
keepalive/
├── main.sh        # Script utama (monitoring loop)
├── start.sh       # Jalankan di background
├── stop.sh        # Hentikan script
├── restart.sh     # Restart script
├── status.sh      # Cek status & website
├── config.sh      # Semua konfigurasi
├── logs.txt       # File log otomatis
└── README.md      # Dokumentasi ini
```

---

## 📝 Contoh Log (`logs.txt`)

```
[2025-05-25 14:00:01] [INFO]  Script dimulai. PID: 12345
[2025-05-25 14:00:02] [OK]    [https://example.com] Online – HTTP 200 – 312ms
[2025-05-25 14:01:02] [OK]    [https://example.com] Refresh #2 – HTTP 200 – 298ms
[2025-05-25 14:05:00] [WARN]  Internet terputus. Menunggu koneksi...
[2025-05-25 14:05:35] [INFO]  Internet kembali tersedia.
[2025-05-25 14:05:36] [ERROR] [https://example.com] OFFLINE – HTTP 503 – 1200ms
[2025-05-25 14:06:36] [OK]    [https://example.com] Online – HTTP 200 – 280ms
```

---

## ❓ Troubleshooting

| Masalah | Solusi |
|---|---|
| `curl: not found` | `pkg install curl` |
| Notifikasi tidak muncul | Install Termux:API dari F-Droid, aktifkan izin notifikasi |
| Script berhenti saat layar mati | Nonaktifkan battery optimization untuk Termux |
| Browser tidak terbuka | Pastikan ada browser terinstall, atau set `ENABLE_BROWSER=false` |
| Permission denied | `chmod +x *.sh` |

---

## 📱 Kompatibilitas

- Android 10+ ✓
- Termux (F-Droid) ✓
- Arsitektur ARM, ARM64, x86 ✓
