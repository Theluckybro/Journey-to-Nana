# Dialogic Timeline Notes

## Active Timelines
- `gamestart.dtl`: intro pembuka MainFloor.
- `interactables.dtl`: interaksi pendek/shared seperti door, bucket, cupboard, dan hotkey HP (label `phone_*`).
- `day1_classroom_intro.dtl`: timeline legacy (diarsipkan, flow Day 1 aktif sekarang lewat TimeskipManager).
- `desk_letters.dtl`: interaksi meja + koleksi surat, dipisah karena percabangannya panjang.
- `npc_1.dtl`: dialog utama NPC 1, hasil gabungan branch `npc_1_1`, `npc_1_2`, dan `npc_default`.
- `npc_2.dtl`: dialog utama NPC 2, hasil gabungan branch `npc_2_1` dan `npc_default`.
- `npc_3.dtl`: dialog utama NPC 3.

## Current Source of Truth for NPC Dialog
- Dialog utama NPC sekarang mulai dari file Dialogic `.dtl` baru per NPC.
- `Resources/Dialog/dialog_data.json` masih dipakai sementara untuk metadata branch order dan kompatibilitas quest unlock/objective.
- `Scripts/NPC.gd` menjadi jembatan antara Dialogic timeline, objective quest, dan quest offering.

## Legacy Cleanup Status
- File legacy NPC timeline (`npc_1_1.dtl`, `npc_1_2.dtl`, `npc_1_default.dtl`, `npc_2_1.dtl`, `npc_2_default.dtl`, `npc_3_1.dtl`) sudah dihapus.
- Gameplay NPC aktif diarahkan ke `npc_1.dtl`, `npc_2.dtl`, dan `npc_3.dtl`.
