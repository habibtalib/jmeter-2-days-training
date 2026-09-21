# Panduan Persediaan — Windows 10/11

Panduan pemasangan untuk peserta yang menggunakan **Windows**. (Pengguna macOS/Linux: ikut bahagian *Persediaan* dalam [`hari-1/README.md`](./hari-1/README.md).)

Kita perlukan **tiga** perisian: **Java (JDK)**, **Apache JMeter**, dan **Node.js** (untuk menjalankan Sistem Under Test tiruan). Semuanya **percuma**.

> ⚠️ **Peringatan etika:** Semua ujian menyasarkan aplikasi tiruan tempatan (`sut/`, `http://localhost:3000`) sahaja — **bukan** laman JPJ sebenar. Menguji beban sistem awam tanpa kebenaran bertulis menyalahi undang-undang (menyerupai serangan DoS).

---

## 1. Pasang Java (JDK 17 atau 21 LTS)

JMeter berjalan atas **Java**. Pilih salah satu cara:

- **winget** (Windows 10/11, paling mudah) — buka **PowerShell** atau **Command Prompt (CMD)** dan taip:
  ```powershell
  winget install EclipseAdoptium.Temurin.21.JDK
  ```
- **Pemasang manual** — muat turun **Temurin JDK 21 (MSI)** dari [adoptium.net](https://adoptium.net/), jalankan pemasang. Semasa pemasangan, **tandakan** pilihan *"Set JAVA_HOME variable"* dan *"Add to PATH"*.

**Sahkan** (buka tetingkap terminal **baharu** supaya PATH dikemas kini):
```powershell
java -version
```
Sepatutnya memaparkan `openjdk version "21..."`.

> **Jika `java` tidak dikenali:** Buka *Settings → System → About → Advanced system settings → Environment Variables*. Tambah **JAVA_HOME** = folder JDK (cth. `C:\Program Files\Eclipse Adoptium\jdk-21...`), dan tambah `%JAVA_HOME%\bin` ke dalam **Path**. Tutup & buka semula terminal.

---

## 2. Pasang Apache JMeter

- Muat turun binari **`apache-jmeter-5.6.3.zip`** dari [jmeter.apache.org/download_jmeter.cgi](https://jmeter.apache.org/download_jmeter.cgi) (bahagian *Binaries*).
- **Nyahzip** ke lokasi mudah, contohnya `C:\apache-jmeter-5.6.3`.
  > **Elakkan** laluan yang mengandungi **ruang** atau folder **OneDrive** yang disegerak — ia kadangkala menyukarkan JMeter.
- **Lancarkan GUI:** buka folder `bin`, **klik dua kali `jmeter.bat`**. Atau dari terminal:
  ```powershell
  cd C:\apache-jmeter-5.6.3\bin
  .\jmeter.bat
  ```

> **(Pilihan) Jadikan `jmeter` boleh dipanggil di mana-mana:** tambah `C:\apache-jmeter-5.6.3\bin` ke dalam **Path** (Environment Variables). Selepas itu anda boleh taip `jmeter` sahaja dalam mana-mana folder.

> **Nota:** `jmeter.bat` ialah versi GUI; `jmeter.bat -n ...` menjalankan mod non-GUI (rujuk Langkah 6).

---

## 3. Pasang Node.js (untuk SUT tiruan)

- **winget:**
  ```powershell
  winget install OpenJS.NodeJS.LTS
  ```
- atau muat turun **LTS MSI** dari [nodejs.org](https://nodejs.org/).

**Sahkan** (terminal baharu):
```powershell
node -v
```
(Perlu **Node.js 18+**. Tiada `npm install` diperlukan — SUT tanpa dependency.)

---

## 4. Jalankan Sistem Under Test (Portal eJPJ tiruan)

Buka satu terminal dan biarkan ia berjalan sepanjang bengkel:

```powershell
cd C:\path\ke\jmeter-2-days-training\sut
node server.js
```

Anda sepatutnya nampak `Portal eJPJ (TIRUAN) berjalan di  http://localhost:3000`. Buka URL itu dalam pelayar untuk senarai endpoint.

> **Windows Defender Firewall:** kali pertama `node server.js` dijalankan, Windows mungkin bertanya kebenaran rangkaian — **benarkan** untuk *Private networks* (cukup untuk localhost).

---

## 5. Jalankan JMeter GUI + buka Test Plan

1. Lancarkan `jmeter.bat` (Langkah 2).
2. **File → Open** → layari ke `jmeter-2-days-training\hari-2\test-plans\05-transaksi-penuh.jmx`.
3. Klik butang **Start (▶ hijau)** untuk menjalankan. Klik **Summary Report** dalam pokok untuk melihat keputusan.

> GUI adalah untuk **membina & menyahpepijat** sahaja. Untuk **beban sebenar**, guna mod **non-GUI** (Langkah 6).

---

## 6. Larian Non-GUI + Laporan HTML (Windows)

**Cara mudah — guna skrip yang disediakan** (`hari-2\run\run-nogui.bat`):

```powershell
cd C:\path\ke\jmeter-2-days-training\hari-2\run
run-nogui.bat
```

Untuk ubah beban:
- **CMD:**
  ```cmd
  set PENGGUNA=200 & set TEMPOH=300 & run-nogui.bat
  ```
- **PowerShell:**
  ```powershell
  $env:PENGGUNA=200; $env:TEMPOH=300; .\run-nogui.bat
  ```

Laporan HTML akan berada di `hari-2\run\hasil\<cap-masa>\laporan\index.html`.

**Cara penuh (arahan langsung)** — pastikan `jmeter.bat` dalam PATH atau guna laluan penuh. Dalam CMD, guna `^` untuk sambung baris (PowerShell guna `` ` ``):

```cmd
jmeter -n -t hari-2\test-plans\06-ujian-beban-nogui.jmx ^
  -Jpengguna=100 -Jrampup=30 -Jtempoh=180 ^
  -l results.jtl ^
  -e -o laporan
```

Kemudian buka `laporan\index.html` dalam pelayar.

---

## Nota Khusus Windows

| Perkara | Petua |
|---------|-------|
| **PATH tidak berkuat kuasa** | Selepas memasang apa-apa, buka tetingkap terminal **baharu**. |
| **Ruang / OneDrive** | Letak folder JMeter, repo, & hasil di laluan tanpa ruang & bukan dalam OneDrive yang belum segerak. |
| **`jmeter` tak dikenali** | Guna laluan penuh `C:\apache-jmeter-5.6.3\bin\jmeter.bat`, atau tambah `bin` ke Path. |
| **Backslash vs slash** | Laluan Windows guna `\`. Dalam fail `.jmx`, CSV `filename` guna `../data/...` — JMeter menerimanya di Windows juga. |
| **CMD vs PowerShell** | Tetapan env var berbeza: CMD `set X=Y & cmd`; PowerShell `$env:X=Y; cmd`. |
| **Heap memori (beban besar)** | Untuk beban tinggi, edit `HEAP` dalam `bin\jmeter.bat` (cth. `set HEAP=-Xms1g -Xmx1g`). |

---

## Semakan Pantas (checklist)

- [ ] `java -version` → JDK 17/21
- [ ] `jmeter.bat` membuka GUI JMeter
- [ ] `node -v` → v18+
- [ ] `node server.js` → `http://localhost:3000` berfungsi (buka dalam pelayar)
- [ ] JMeter GUI boleh buka `hari-2\test-plans\05-transaksi-penuh.jmx` dan **Start** tanpa ralat
- [ ] `run-nogui.bat` menjana `laporan\index.html`

Selepas semua ✔️, anda bersedia mengikuti [Hari 1](./hari-1/README.md).
