# Naskah Game Journey to Nana

## Act 1 - Surabaya

Dokumen ini jadi acuan alur cerita untuk developer agar sinkron antara naskah, timeline Dialogic, dan implementasi gameplay.

## Status Implementasi Saat Ini

- Implemented: Day 1 (06:30 AM sampai 07:00 AM) sudah playable.
- Implemented: Quest pagi Siap-siap Kuliah (mandi dan ganti baju) sudah aktif.
- Implemented: Gate pintu utama tetap pakai syarat quest selesai, tapi beat kampus dipindah ke sistem timeskip (tanpa load scene Classroom).
- Implemented: Beat kampus singkat (07:00 AM) lalu timeskip ke 14:30 PM (pulang kampus) sudah aktif.
- Implemented: Order makanan via hotkey HP lalu timeskip ke 15:15 PM + notifikasi Shopee sudah aktif.
- Planned: Day 1 (08:00 PM, 01:00 AM) belum diimplementasi penuh.
- Planned: Day 2 belum diimplementasi penuh.

## Day 1

### Scene: Kamar Kos Indra (Pixel Art)

Player bisa menggerakkan karakter Indra di dalam kamar kecil.

### 06:30 AM

Sound Effect: Alarm Digital.

(Indra bangun dari kasur)

Indra (Monolog):
Satu hari lagi. Panas lagi. Kuliah lagi. Males banget mandi, tapi mau gimana lagi.

System Message:
Quest Added - Siap-siap Kuliah
Objective: Mandi dan Ganti Baju

(Player klik Pintu saat belum siap-siap)
Indra:
Keluar dengan muka bantal dan bau acem begini? Bisa di-roasting ibu kos nanti. Mandi dulu lah.

(Player klik Ember - Mandi)
Sound Effect: Suara gayung dan air (Byur)
Indra:
Brrr dingin banget. Malesnya mandi pagi gini nih. Pasti selalu aja kedinginan.

System Message:
Objective Updated (1/2 Complete)

(Player klik Lemari - Ganti Baju)
Indra:
Pake baju yang mana ya? Ah, kemeja ijo lagi dah. Bodo amat, dosen juga nggak bakal notice gue pake baju apa.

System Message:
Objective Updated (2/2 Complete)

System Message:
Quest Complete - Siap-siap Kuliah

(Player klik Pintu setelah siap)
Indra:
Oke dah siap semua, gas berangkat!

(Scene Fade Out - teleport ke Kampus)

### 07:00 AM - Kampus (Timeskip Narasi)

(Tidak pindah scene Classroom. Beat kampus ditampilkan sebagai narasi singkat.)

Narasi:
Dosen menjelaskan teori yang entah kapan akan dipakai.

Indra (Monolog):
Bosan.

(Timeskip ke 14:30 PM - Pulang Kost)

### 14:30 PM - Pulang Kost

(Player kembali di MainFloor dan bisa bergerak normal)

(Player tekan hotkey keyboard P untuk buka HP)

UI HP:
Pilih Makanan -> Ayam Geprek (Lagi)

### 15:15 PM - Notifikasi Pesanan

Sound Effect: Notifikasi Shopee/bel.

(Setelah order makanan, game menampilkan beat notifikasi singkat lewat timeskip)

Indra:
Pesanan ayam geprek otw.

### 08:00 PM (Planned)

(Player interaksi dengan PC/Laptop)

UI Laptop:
Buka Roblox.

Indra:
Apaan sih gamenya gaje semua. Tycoon lagi, simulator lagi. Kalau main sendiri nggak asik.

(Sound Effect: Klik mouse -> Hening)

Indra:
Dahlah. Alt+F4.

### 01:00 AM (Planned)

(Player interaksi dengan kasur)

Indra:
Besok paling begini lagi.

(Layar Fade Out - Tidur)

## Day 2 (Planned)

### 08:15 PM - Kamar Kos

(Indra duduk di depan PC. Bosan)

Indra:
Gabut banget.

(Player buka HP -> Chat Ethan)

Indra:
Tenn, login Roblox yok. Gabut nih.

Ethan:
Gas. Discord biasa.

(Layar PC menyala. Muncul portrait/bubble chat Ethan di layar)

Ethan:
Halo. Tumben ngajak main.

Indra:
Ya daripada bengong. Main apaan nih?

Ethan:
Bentar, gue ajak Nana ya. Boleh kan?

Indra:
Nana? Oh, yang Masbro ini bukan sih?

Ethan:
Yoi, itu Nana. Dia mau ikut katanya.

(Sound Effect: User Joined Discord)

Nana:
Halo, Ethan!

Ethan:
Halo, Na. Nih ada Indra juga.

Indra:
Halo, Na.

(Jeda sejenak)

Nana:
Eh? Tunggu, kok kayak kenal suaranya? Kamu Davin kah?
Eh tapi bukan deng... Davin suaranya lebih ngebass lagi. Ini... Indra ya?

Indra (Dalam Hati):
Dia bingung. Isengin dikit kali ya.

Indra:
Iyaa, emang kok. Namaku Davindra.

Nana:
Hah? Davindra?

Indra:
Iya, Davindra. Jadi mau dipanggil Davin bisa, mau dipanggil Indra juga bisa. Sama aja. Yakan Ten?

Ethan:
Yoi.

Nana:
Ohhh gitu! Oke deh, Davindra. Unik juga ya namanya digabung gitu, pas banget.

(Scene game: Karakter Nana/Masbro muncul di layar PC Indra)

Narasi:
Karakter Masbro melompat-lompat mendekati Indra.

(Time skip, tanpa gameplay di dalam game)

Layar Fade Out (hitam)
Teks layar: 2 Jam Kemudian...
Sound Effect: Suara keyboard cepat dan ketawa samar.

Layar Fade In (kembali ke Kamar Kos)
(Posisi Indra masih di depan PC, jam dinding menunjukkan 11:00 PM)

Ethan:
Gila, capek banget gue ketawa. Udahan dulu lah, besok gue kelas pagi.

Nana:
Iya nih, suaraku sampe serak gara-gara Davindra iseng banget tadi.

(Beat reveal)

Indra:
Btw, Na. Ada plot twist dikit sebelum tidur.

Nana:
Apa tuh?

Indra:
Sebenernya... Davin sama Indra itu dua orang beda. Gue Indra. Davindra itu karangan gw doang tadi.

Ethan:
Wkwkwk.

(Jeda/Hening)

Nana:
HAH?! Jadi aku dikerjain dari awal?!

Indra:
Ya maap, abis kamu lucu banget sih langsung percaya tadi.

Nana:
IIIHH! Kalian jahat banget sumpah! Ethan juga kenapa diem aja?!

Ethan:
Seru soalnya liat lo percaya.

Nana:
Nyebelin! Awas ya kalian!

(Catatan ekspresi: marah cemberut, bukan benci)

Nana:
Yaudah deh. Bye INDRA. Bukan Davindra.

Indra:
Hahaha. Bye, Na.

(Sound Effect: Call Disconnected)

### Ending Day 2

(Indra bersandar di kursi)

Indra:
Not bad.

(Muncul indikator mood/happiness sedikit naik)

Indra:
Kayaknya besok gue bakal login lagi.

(Layar Fade Out - Save Game)

## Catatan Sinkronisasi Teknis

- Alur Day 1 yang sudah aktif memakai timeline gamestart + interactables, sedangkan beat kampus diganti sistem timeskip (tanpa load scene Classroom).
- Pintu masih model auto trigger, bukan klik E khusus.
- Interaksi HP memakai hotkey keyboard (P), bukan objek kasur.
- Order HP pertama memicu timeskip kedua ke 15:15 + notifikasi Shopee dengan player lock sementara.
- UI PC/Laptop belum jadi dependency implementasi pada fase ini.
- Speaker Narasi saat ini ditulis langsung di timeline, belum jadi file character dch terpisah.
- Dokumen ini adalah acuan cerita; detail teknis implementasi bisa berubah selama tidak mengubah intent cerita utama.
