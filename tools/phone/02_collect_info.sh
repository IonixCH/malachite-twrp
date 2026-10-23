#!/system/bin/sh
# Kumpulkan info HP buat nyocokin build recovery. Tidak menulis ke partisi.
# Jalankan dari Termux (butuh root):   su -c "sh /sdcard/02_collect_info.sh"
# Hasil: /sdcard/malachite-info.txt  -> isinya boleh dikirim ke Claude (serial/IMEI disaring).

OUT="${1:-/sdcard/malachite-info.txt}"
if [ -z "$SKIP_ROOT_CHECK" ] && [ "$(id -u)" != "0" ]; then
  echo "Butuh root. Jalankan: su -c \"sh $0\""
  exit 1
fi
command -v getprop >/dev/null 2>&1 || getprop() { echo ""; }

filter() { grep -v -i -E 'serial|imei|meid|androidboot\.hwc|oaid|wifimac|btmac'; }

{
echo "== waktu =="; date
echo; echo "== kernel =="; uname -a
echo; echo "== properti dasar =="
for p in ro.product.model ro.product.device ro.product.name ro.product.marketname \
         ro.build.fingerprint ro.build.version.release ro.build.version.security_patch \
         ro.boot.slot_suffix ro.boot.hardware ro.boot.verifiedbootstate ro.boot.flash.locked \
         ro.boot.vbmeta.device_state ro.virtual_ab.enabled ro.crypto.state ro.crypto.type \
         ro.crypto.volume.filenames_mode ro.boot.dynamic_partitions; do
  echo "$p=$(getprop $p)"
done
echo; echo "== slot (bootctl) =="
if command -v bootctl >/dev/null 2>&1; then
  echo "current-slot: $(bootctl get-current-slot 2>&1)"
  for s in 0 1; do
    echo "slot $s bootable: $(bootctl is-slot-bootable $s 2>&1) | successful: $(bootctl is-slot-marked-successful $s 2>&1)"
  done
else
  echo "bootctl tidak tersedia"
fi
echo; echo "== cmdline (disaring) =="
cat /proc/cmdline 2>/dev/null | tr ' ' '\n' | filter
echo; echo "== bootconfig (disaring) =="
cat /proc/bootconfig 2>/dev/null | filter
echo; echo "== mount /metadata & /data =="
grep -E ' /metadata | /data ' /proc/mounts
echo; echo "== fstab userdata (vendor) =="
for f in /vendor/etc/fstab.mt6878 /vendor/etc/fstab.emmc; do
  [ -f "$f" ] && { echo "[$f]"; grep -E 'userdata|metadata' "$f"; }
done
echo; echo "== daftar partisi by-name =="
ls /dev/block/by-name 2>/dev/null
echo; echo "== modul termuat (urutan) =="
awk '{print $1}' /proc/modules 2>/dev/null
echo; echo "== modul touch/panel di vendor_dlkm & vendor =="
for d in /vendor_dlkm/lib/modules /vendor/lib/modules; do
  [ -d "$d" ] && { echo "[$d]"; ls "$d" | grep -i -E 'focal|goodix|touch|fts|tp_|xiaomi_touch|haptic|panel'; }
done
echo; echo "== super / partisi dinamis (lpdump) =="
if command -v lpdump >/dev/null 2>&1; then lpdump 2>&1 | head -60; else echo "lpdump tidak tersedia"; fi
} > "$OUT" 2>&1

echo "Selesai. Hasil di: $OUT"
echo "Cek isinya sekali lagi; kalau ada data pribadi yang lolos, hapus barisnya sebelum dikirim."
