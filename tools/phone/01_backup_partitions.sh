#!/system/bin/sh
# Backup partisi penting ke penyimpanan HP. HANYA MEMBACA partisi, tidak menulis apa pun ke partisi.
# Jalankan dari Termux (butuh root):   su -c "sh /sdcard/01_backup_partitions.sh"
# Hasil: folder /sdcard/malachite-backup-<waktu>/ berisi *.img + SHA256SUMS.txt
#
# PENTING: file hasil backup berisi data unik HP lu (kalibrasi/IMEI). Salin ke tempat aman di LUAR HP
# (PC, cloud pribadi, flashdisk OTG) dan JANGAN diupload ke repo/forum publik.

BYNAME="${BYNAME:-/dev/block/by-name}"

if [ -z "$SKIP_ROOT_CHECK" ] && [ "$(id -u)" != "0" ]; then
  echo "Butuh root. Jalankan: su -c \"sh $0\""
  exit 1
fi
command -v getprop >/dev/null 2>&1 || getprop() { echo ""; }

STAMP=$(date +%Y%m%d-%H%M%S)
DEST="${1:-/sdcard/malachite-backup-$STAMP}"
mkdir -p "$DEST" || { echo "Gagal bikin folder $DEST"; exit 1; }

# Grup 1: kalibrasi/IMEI/identitas (paling penting)
GROUP_CAL="nvram nvdata nvcfg protect1 protect2 proinfo persist frp seccfg efuse"
# Grup 2: rantai boot (buat jalan balik kalau flash recovery gagal)
GROUP_BOOT="boot_a boot_b init_boot_a init_boot_b vendor_boot_a vendor_boot_b dtbo_a dtbo_b vbmeta_a vbmeta_b vbmeta_system_a vbmeta_system_b vbmeta_vendor_a vbmeta_vendor_b"
# Grup 3: firmware level rendah
GROUP_FW="lk_a lk_b tee_a tee_b preloader_raw_a preloader_raw_b"

echo "Slot aktif: $(getprop ro.boot.slot_suffix)"
echo "Tujuan: $DEST"
echo

ok=0; skip=0; fail=0
: > "$DEST/SHA256SUMS.txt"
for n in $GROUP_CAL $GROUP_BOOT $GROUP_FW; do
  src="$BYNAME/$n"
  if [ ! -e "$src" ]; then
    echo "SKIP  $n (tidak ada di by-name)"
    skip=$((skip+1)); continue
  fi
  out="$DEST/$n.img"
  if dd if="$src" of="$out" bs=1048576 2>/dev/null; then
    h_src=$(sha256sum "$src" 2>/dev/null | cut -d' ' -f1)
    h_out=$(sha256sum "$out" 2>/dev/null | cut -d' ' -f1)
    if [ -n "$h_src" ] && [ "$h_src" = "$h_out" ]; then
      echo "$h_out  $n.img" >> "$DEST/SHA256SUMS.txt"
      echo "OK    $n"
      ok=$((ok+1))
    else
      echo "GAGAL $n (checksum salinan tidak cocok)"
      rm -f "$out"; fail=$((fail+1))
    fi
  else
    echo "GAGAL $n (dd error)"
    rm -f "$out"; fail=$((fail+1))
  fi
done

ls "$BYNAME" > "$DEST/by-name-list.txt" 2>/dev/null

echo
echo "Selesai: OK=$ok SKIP=$skip GAGAL=$fail"
du -sh "$DEST" 2>/dev/null
echo
echo "LANGKAH WAJIB: salin folder $DEST ke luar HP sekarang, lalu cek SHA256SUMS.txt di sana."
[ "$fail" = "0" ] || echo "Ada yang GAGAL: jangan lanjut ke tahap flash sebelum dibereskan."
