### DialogUI.gd

extends Control

@onready var panel = $CanvasLayer/Panel
@onready var dialog_speaker = $CanvasLayer/Panel/DialogBox/DialogSpeaker
@onready var dialog_text = $CanvasLayer/Panel/DialogBox/DialogText
@onready var dialog_options = $CanvasLayer/Panel/DialogBox/DialogOptions

var has_continue := false
var _continue_callback: Callable = Callable()

func _ready():
	hide_dialog()
	
# show dialog box
func show_dialog(speaker, text, options, continue_callback: Callable = Callable()):
	panel.visible = true
	_continue_callback = continue_callback
	
	# Populate data
	dialog_speaker.text = speaker
	dialog_text.text = text
	
	# Remove exisiting options
	for option in dialog_options.get_children():
		dialog_options.remove_child(option)
		
	# Populate options
	for option in options.keys():
		var button = Button.new()
		button.text = option
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_on_option_selected.bind(option))
		dialog_options.add_child(button)

	# If no options were provided, show a Continue button so the player can progress
	if not options or options.size() == 0:
		var cont = Button.new()
		cont.text = "Continue"
		cont.add_theme_font_size_override("font_size", 20)
		if _continue_callback.is_valid():
			cont.pressed.connect(_on_continue_selected)
		else:
			# Pass an empty string - DialogManager will handle empty-option (auto-advance)
			cont.pressed.connect(_on_option_selected.bind(""))
		dialog_options.add_child(cont)
		has_continue = true

	# Ensure player can't move while dialog is open
	if Global.player:
		Global.player.can_move = false

# Handle response selection	
func _on_option_selected(option):
	get_parent().handle_dialog_choice(option)

func _on_continue_selected() -> void:
	var callback := _continue_callback
	hide_dialog()
	if callback.is_valid():
		callback.call()
	
# hide dialog box
func hide_dialog():
	panel.visible = false
	# Only modify player movement if a player exists (avoid Nil errors during startup)
	if Global.player:
		Global.player.can_move = true
	has_continue = false
	_continue_callback = Callable()


func _unhandled_input(event):
	# Allow keyboard/gamepad press (ui_accept) to advance linear dialogs
	if panel.visible and has_continue and event.is_action_pressed("ui_accept"):
		if _continue_callback.is_valid():
			_on_continue_selected()
		else:
			_on_option_selected("")


func _on_close_button_pressed() -> void:
	hide_dialog()
