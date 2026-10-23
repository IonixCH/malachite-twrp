# Langkah dari HP (Termux + root). Jangan loncat urutan.

## Fase 0 — Syarat
- Root jalan (su di Termux), akun GitHub, Termux terbaru.
- JALAN BALIK: akses ke PC/laptop (boleh pinjam) yang bisa fastboot + paket fastboot firmware stock yang SAMA dengan yang terpasang.
  Kalau sama sekali nggak punya, berhenti sebelum Fase 4.

## Fase 1 — Backup partisi (aman, cuma baca)
```
pkg update && pkg install coreutils
termux-setup-storage
# taruh 01_backup_partitions.sh di /sdcard/Download/ lalu:
su -c "sh /sdcard/Download/01_backup_partitions.sh"
```
Pastikan hasilnya OK semua untuk grup kalibrasi (nvram, nvdata, nvcfg, protect1/2, proinfo, persist) dan boot_a/b, vendor_boot_a/b.
Salin foldernya ke LUAR HP (PC/cloud pribadi/OTG). Jangan diupload publik.

## Fase 2 — Kumpulkan info
```
su -c "sh /sdcard/Download/02_collect_info.sh"
```
Kirim isi /sdcard/malachite-info.txt ke Claude (serial/IMEI sudah disaring, tetap cek sekali).
Dari situ ditentukan: modul yang cocok, modul touch, DTB, dan apakah slot lawan aman buat tes.
(Opsional, setelah dicek bareng) ambil DTB dari vendor_boot milik lu sendiri:
```
pkg install python git
git clone https://android.googlesource.com/platform/system/tools/mkbootimg
python3 mkbootimg/unpack_bootimg.py --boot_img /sdcard/malachite-backup-*/vendor_boot_a.img --out ~/vb
cp ~/vb/dtb override/dtb
```

## Fase 3 — Build di GitHub (repo PRIVATE, karena ada firmware Xiaomi di dalamnya)
```
pkg install git gh unzip
cd ~ && unzip /sdcard/Download/malachite-twrp.zip && cd malachite-twrp
git init -b main && git add -A && git commit -m "malachite twrp v2"
gh auth login
gh repo create malachite-twrp --private --source=. --push
gh workflow run build-twrp.yml -f selinux_permissive=false
gh run watch
gh run download -n twrp-malachite
```
Kalau gagal: `gh run download -n build-log` lalu kirim errornya. Cek kuota menit Actions untuk repo private.
Hasil: vendor_boot.img + SHA256SUMS.txt + build-info.txt. Cocokkan sha256 sebelum dipakai.

## Fase 4 — Tes di slot LAWAN (slot aktif jangan disentuh)
Syarat: slot lawan bootable (lihat malachite-info.txt: `bootctl is-slot-bootable`), backup Fase 1 sudah di luar HP, jalan balik siap.
```
su -c 'getprop ro.boot.slot_suffix'            # misal _a -> lawan = _b (angka slot 1)
SZ=$(stat -c %s /sdcard/Download/vendor_boot.img)
su -c 'dd if=/sdcard/Download/vendor_boot.img of=/dev/block/by-name/vendor_boot_b bs=1M conv=fsync'
su -c "head -c $SZ /dev/block/by-name/vendor_boot_b | sha256sum"   # harus sama dengan sha256 file
su -c 'bootctl set-active-boot-slot 1'
su -c 'reboot recovery'
```
Di recovery, CUMA PERIKSA (jangan wipe/format/flash dulu): layar, touch, apakah /data minta password/kebuka, MTP, adb.
Kembali ke Android: menu Reboot di TWRP pilih slot A, atau dari PC: `fastboot --set-active=a` lalu `fastboot reboot`.
Kalau layar mati/bootloop: tahan Power + Vol- masuk fastboot, lalu dari PC `fastboot --set-active=a`.
Kirim hasil pengamatan ke Claude.

## Fase 5 — Pakai
Baru setelah tes lulus. Catatan: vendor_boot yang sama dipakai boot Android normal, jadi TWRP permanen di slot aktif
adalah langkah terpisah (kemungkinan butuh vendor_boot gabungan stock + recovery fragment TWRP). Bahas dulu.

## Jangan
- Format Data / wipe / flash ROM di tes pertama.
- Flash OTA stock atau payload.bin lewat recovery ini.
- Install Image ke partisi selain boot/init_boot/vendor_boot (sudah dikunci di menu, jangan dibuka lagi).
- Upload repo ini ke publik atau backup ke mana pun.
