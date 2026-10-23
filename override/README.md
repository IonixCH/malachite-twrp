Folder opsional. Isi dari firmware HP lu sendiri (bukan dari internet):

  override/dtb          <- file `dtb` hasil unpack_bootimg dari vendor_boot.img stock ROM yang lu pakai
  override/modules/*    <- modul .ko + modules.load.recovery yang cocok dengan kernel ROM lu
                           (jangan isi sebelum dicek bareng; salah modul = layar/touch mati)

Kalau folder ini kosong, build memakai file bawaan repo upstream (DTB 395011 byte, modul vermagic 6.1.138).
