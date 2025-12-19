extends Node

signal alarm_finished

#This class preloads all of our sound effects so that they can be played at a momets notice
#region Preloaded Sounds
const PLAYER_ATTACK_HIT = preload("res://Art/Audio/Effects/AttackHit.ogg")
const PLAYER_ATTACK_SWING = preload("res://Art/Audio/Effects/AttackSwing.ogg")
const ENEMY_HIT = preload("res://Art/Audio/Effects/Enemy_hit.ogg")
const BLOODY_HIT = preload("res://Art/Audio/Effects/bloody_hit.ogg")
const COIN_PICK = preload("res://Art/Audio/Effects/coin_pick.ogg")
const ALARM_SOUND = preload("res://Art/Audio/Effects/AlarmAudio.mp3")

#endregion

var audio_players = []
var max_players = 8
var starting_players = 3

var active_alarm_player: AudioStreamPlayer = null

func _ready() -> void:
	initiate_audio_stream()
	
#Play a sound, call this function from anywhere
#offset lets you start the sound with an offset, like starting the sound at 0.1s into the clip
#Arguments(audio_clip, offset, volume)
#Example when calling this function:
#AudioManager.play_sound(AudioManager.PLAYER_ATTACK_SWING, 0.25, 1)
func play_sound(audiostream : AudioStream, offset : float, volume : float):
	#Loop through and find an available player currently not playing a sound
	var available_player = audio_players[0]
	for player in audio_players:
		if not player.is_playing():
			available_player = player
			break

	# If no player is available and we havent reached the maximum amount of players, create a new one
	if available_player == null and audio_players.size() < max_players:
		available_player = AudioStreamPlayer.new()
		audio_players.append(available_player)
		add_child(available_player)

	available_player.stream = audiostream
	available_player.pitch_scale = randf_range(0.9, 1.1)
	available_player.volume_db = volume
	available_player.play(offset)

#Instantiate audiostreams into the scene
func initiate_audio_stream():
	for i in range(starting_players):
		var player = AudioStreamPlayer.new()
		audio_players.append(player)
		add_child(player)

func play_alarm():
	if active_alarm_player == null:
		active_alarm_player = AudioStreamPlayer.new()
		add_child(active_alarm_player)
	
	if not active_alarm_player.is_playing():
		active_alarm_player.stream = ALARM_SOUND
		active_alarm_player.volume_db = 0.0
		active_alarm_player.pitch_scale = 1.0
		# Connect finished signal untuk emit alarm_finished
		if not active_alarm_player.is_connected("finished", _on_alarm_finished):
			active_alarm_player.finished.connect(_on_alarm_finished)
		active_alarm_player.play()

func stop_alarm():
	if active_alarm_player != null and active_alarm_player.is_playing():
		active_alarm_player.stop()

func _on_alarm_finished():
	alarm_finished.emit()