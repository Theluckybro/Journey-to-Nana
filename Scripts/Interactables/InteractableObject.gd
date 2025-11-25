extends StaticBody2D
class_name InteractableObject

@export_category("Quest Settings")
@export var interaction_id: String = ""       # ID yang dicocokkan dengan Objective di Resource Quest
@export var interaction_type: String = ""     # Tipe objektif (samakan dengan di Resource Quest)
@export var interaction_quantity: int = 1     # Berapa progress yang didapat

@export_category("Dialogic Settings")
@export var timeline_name: String = "interactables" # Nama file timeline dtl
@export var timeline_label: String = ""       # Label spesifik (jump label) di dalam timeline
@export var confirm_signal: String = ""   # Argument signal yang ditunggu dari Dialogic untuk confirm

var _initiating_player: PlayerMain = null

# Dipanggil oleh PlayerMain saat menekan tombol Interact
func interact(by_player: PlayerMain) -> void:
	print("Interacting with: ", interaction_id)
	if by_player == null:
		return
	
	_initiating_player = by_player
	
	# Mulai dialogic
	if timeline_label != "":
		Dialogic.start(timeline_name, timeline_label)
	else:
		Dialogic.start(timeline_name)
		
	# Sambungkan signal listener hanya jika belum tersambung
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)

# Mendengarkan sinyal dari [signal arg="..."] di Dialogic
func _on_dialogic_signal(argument: String):
	# Cek apakah argumennya cocok (misal: player memilih "Ya" -> "bucket_yes")
	if argument == confirm_signal:
		print("Interaction confirmed: ", interaction_id)
		
		if _initiating_player:
			# Kirim progress ke sistem quest Player
			_initiating_player.check_quest_objectives(interaction_id, interaction_type, interaction_quantity)
		
		# Opsional: Putus koneksi signal setelah selesai agar rapi
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
