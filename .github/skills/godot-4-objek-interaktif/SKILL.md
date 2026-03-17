---
name: godot-5-objek-interaktif
description: 'Buat objek interaktif Godot 4.6 di proyek ini: setup node + group, script interact(), Dialogic timeline/signal_event, dan update quest objective. Gunakan saat user meminta cara membuat objek interaktif, interactable object, interaksi item, atau integrasi Dialogic interaction.'
argument-hint: 'Nama objek, jenis node (StaticBody2D/Area2D), timeline, label, confirm signal'
---

# Cara Membuat Objek Interaktif Godot 5

## Outcome
- Objek bisa dipilih oleh player sebagai target interaksi.
- Prompt interaksi muncul saat player mendekat.
- Tombol ui_interact memanggil interact(by_player).
- Dialogic timeline berjalan sesuai timeline_name/timeline_label.
- Signal konfirmasi mengupdate objective quest.

## Kapan Digunakan
- Menambah objek baru seperti ember, lemari, pintu, atau item ruangan.
- Mengubah objek statis menjadi objek yang bisa diinteraksikan.
- Menyambungkan interaksi objek dengan Dialogic dan quest progress.

## Workflow
1. Pilih pola objek (decision point).
- Gunakan StaticBody2D jika objek berperan sebagai body statis dengan collision biasa.
- Gunakan Area2D jika interaksi lebih cocok berbasis area trigger.

2. Buat scene node interaktif.
- Buat root node (StaticBody2D atau Area2D).
- Tambahkan Sprite2D/AnimatedSprite2D dan CollisionShape2D.
- Tambahkan group Interactable pada root node.
- Pastikan posisi objek bisa terjangkau oleh InteractArea player.

3. Pasang script interaksi.
- Opsi A (disarankan): pasang script reusable res://Scripts/Interactables/InteractableObject.gd.
- Opsi B: buat script baru meniru pola res://Scripts/Interactables/BucketInteract.gd atau CupboardInteract.gd.
- Wajib: sediakan method interact(by_player) karena PlayerMain akan memanggil method ini untuk node group Interactable.

4. Konfigurasi data interaksi.
- Atur interaction_id, interaction_type, interaction_quantity.
- Atur timeline_name dan opsional timeline_label.
- Atur confirm_signal agar sama persis dengan arg signal Dialogic [signal arg="..."] di timeline.

5. Integrasikan Dialogic signal_event dengan aman.
- Saat interaksi dimulai, simpan referensi player pemicu interaksi.
- Jalankan Dialogic.start(...) sesuai timeline.
- Connect handler _on_dialogic_signal hanya jika belum terkoneksi.
- Di _on_dialogic_signal(argument), proses hanya saat argument == confirm_signal.
- Jika match: jalankan aksi opsional (cutscene/effect), lalu panggil check_quest_objectives(...).
- Disconnect handler setelah konfirmasi agar tidak memicu update dobel.

6. Validasi dari sisi PlayerMain.
- Pastikan object lolos validasi target (group Interactable).
- Cek prompt terlihat saat target dipilih.
- Cek input ui_interact memicu target.interact(self).

7. Uji selesai (completion checks).
- Prompt muncul/hilang sesuai jarak dan target.
- Timeline Dialogic yang benar berjalan.
- Signal confirm hanya memicu sekali.
- Progress quest bertambah sesuai quantity.
- Player lock/unlock bergerak normal saat timeline mulai/selesai.

## Referensi Implementasi Repo
- Scenes/Player/Scripts/PlayerMain.gd: pemilihan target, prompt, dan dispatch interact(self).
- Scripts/Interactables/InteractableObject.gd: pola reusable interaksi + confirm signal.
- Scripts/Interactables/BucketInteract.gd: contoh interaksi custom dengan confirm signal.
- Scripts/Interactables/CupboardInteract.gd: contoh interaksi custom sederhana.
- Scenes/Interactables.tscn: contoh node root dengan group Interactable.

## Troubleshooting Cepat
- Prompt tidak muncul: cek group Interactable, collision shape, dan jangkauan InteractArea.
- Interact tidak terpanggil: cek nama method harus interact, bukan nama lain.
- Quest tidak update: cek confirm_signal harus sama persis dengan argument signal Dialogic.
- Trigger dobel: pastikan koneksi signal tidak berulang dan lakukan disconnect setelah konfirmasi.
