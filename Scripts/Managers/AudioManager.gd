extends Node

signal alarm_finished

# This class preloads sound effects so they can be played quickly.
#region Preloaded Sounds
const PLAYER_ATTACK_HIT = preload("res://Art/Audio/Effects/AttackHit.ogg")
const PLAYER_ATTACK_SWING = preload("res://Art/Audio/Effects/AttackSwing.ogg")
const ENEMY_HIT = preload("res://Art/Audio/Effects/Enemy_hit.ogg")
const BLOODY_HIT = preload("res://Art/Audio/Effects/bloody_hit.ogg")
const COIN_PICK = preload("res://Art/Audio/Effects/coin_pick.ogg")
const ALARM_SOUND = preload("res://Art/Audio/Effects/AlarmAudio.mp3")

#endregion

@export var max_players: int = 8
@export var starting_players: int = 3

var audio_players: Array[AudioStreamPlayer] = []

var active_alarm_player: AudioStreamPlayer = null

func _ready() -> void:
	_init_audio_players()
	
# Play a sound. Call this from anywhere.
# - offset: start time (seconds) within the clip
# - volume: AudioStreamPlayer.volume_db
func play_sound(audiostream: AudioStream, offset: float = 0.0, volume: float = 0.0) -> void:
	if audiostream == null:
		return

	if audio_players.is_empty():
		_init_audio_players()
		if audio_players.is_empty():
			return

	var available_player: AudioStreamPlayer = null
	for player in audio_players:
		if not player.is_playing():
			available_player = player
			break

	# If all players are busy and we haven't reached the max, create a new one.
	if available_player == null and audio_players.size() < max_players:
		available_player = AudioStreamPlayer.new()
		audio_players.append(available_player)
		add_child(available_player)

	# If still none available, reuse the first one (previous behavior).
	if available_player == null:
		available_player = audio_players[0]

	available_player.stream = audiostream
	available_player.pitch_scale = randf_range(0.9, 1.1)
	available_player.volume_db = volume
	available_player.play(offset)

func _init_audio_players() -> void:
	if starting_players <= 0:
		starting_players = 1

	while audio_players.size() < starting_players:
		var player := AudioStreamPlayer.new()
		audio_players.append(player)
		add_child(player)

func play_alarm() -> void:
	if active_alarm_player == null:
		active_alarm_player = AudioStreamPlayer.new()
		add_child(active_alarm_player)
	
	if not active_alarm_player.is_playing():
		active_alarm_player.stream = ALARM_SOUND
		active_alarm_player.volume_db = 0.0
		active_alarm_player.pitch_scale = 1.0
		if not active_alarm_player.finished.is_connected(_on_alarm_finished):
			active_alarm_player.finished.connect(_on_alarm_finished)
		active_alarm_player.play()

func stop_alarm() -> void:
	if active_alarm_player != null and active_alarm_player.is_playing():
		active_alarm_player.stop()

func _on_alarm_finished() -> void:
	alarm_finished.emit()