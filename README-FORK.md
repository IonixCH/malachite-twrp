# Fork rapi: TWRP malachite (basis: mytiantian001/android_device_xiaomi_malachite_twrp, branch A16)

Semua kredit device tree ke penulis aslinya dan kontributornya (lisensi Apache-2.0 tetap berlaku).
Perubahan di fork ini cuma soal keamanan dan proses build. Isi hardware tidak diubah.

## Perubahan dibanding upstream
1. `recovery/root/system/etc/twrp.flags`
   - `flashimg=1` hanya tersisa untuk `/boot`, `/init_boot`, `/vendor_boot` (40 partisi lain dicabut).
     Partisi lain tetap bisa di-BACKUP (`backup=1`), tapi tidak bisa ditulis lewat menu Install Image.
   - Mount ext4 untuk `protect1/2`, `nvdata`, `nvcfg`, `cust`, `mcf_ota` dihapus.
   - Label `/init_boot` yang salah tulis "[ vendor_boot ]" dibetulkan.
2. `BoardConfig.mk`: `androidboot.selinux=permissive` tidak lagi default di cmdline vendor_boot
   (vendor_boot dipakai juga boot Android normal). Bisa dinyalakan lewat input workflow kalau recovery butuh.
3. Tambahan: `.github/workflows/build-twrp.yml`, `tools/phone/*.sh` (backup & kumpul info), `override/`, `STEPS.md`.

## Belum diubah (sengaja, tunggu data HP lu)
- Modul kernel bawaan (vermagic 6.1.138) dan tidak ada modul driver touch.
- DTB bawaan (395011 byte; `BOARD_DTB_SIZE` di BoardConfig tertulis 444463).
- `AB_OTA_PARTITIONS` + postinstall `mtk_plpath_utils`: jangan flash OTA stock/payload.bin lewat recovery ini.
- `BOARD_AVB_ENABLE := true` tanpa kunci, `ro.adb.secure=0`, security patch 2099 (trik TWRP umum).
