extends Label

# TitleAnimator.gd
# Splits the Label's text into individual Label children and animates them
# in a per-letter wave. Designed for Godot 3.x style scenes.

@export var title_text := ""
@export var letter_spacing := 4.0
@export var float_amount := 8.0
@export var wave_speed := 6.0
@export var phase_offset := 0.45
var _container: Control = null
var _time: float = 0.0
@export var randomize_anim := true
@export var amplitude_variation := 0.25
@export var speed_variation := 0.2
@export var phase_variation := 1.0
@export var rng_seed: int = 0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _phases: Array = []
var _amplitudes: Array = []
var _speeds: Array = []

func _ready():
    # If the designer left the text in the Label (in the .tscn), use it.
    if title_text == "":
        title_text = text

    # Clear the source Label text so we can draw letters separately
    text = ""

    # Duplicate label_settings if present so children inherit same font/shadow
    var settings = null
    if has_method("get") and get("label_settings") != null:
        settings = get("label_settings").duplicate()

    # Initialize RNG for randomized per-letter motion
    if rng_seed != 0:
        _rng.seed = rng_seed
    else:
        _rng.randomize()

    # Create a plain Control to manually layout per-letter Labels
    _container = Control.new()
    _container.name = "LettersContainer"
    add_child(_container)

    var x = 0.0
    var max_h = 0.0
    for i in range(title_text.length()):
        var ch = title_text[i]
        var l = Label.new()
        l.text = ch
        if settings:
            l.set("label_settings", settings)
        _container.add_child(l)
        # Let the control compute its natural size, then place it
        l.position = Vector2(x, 0)
        # Force a minimal update so get_minimum_size is meaningful
        l.hide()
        l.show()
        var min_size = l.get_minimum_size()
        x += min_size.x + letter_spacing
        max_h = max(max_h, min_size.y)

        # assign randomized parameters per-letter
        var phase = 0.0
        var amp = float_amount
        var speed_mul = 1.0
        if randomize_anim:
            phase = _rng.randf_range(0.0, phase_variation)
            amp = float_amount * _rng.randf_range(1.0 - amplitude_variation, 1.0 + amplitude_variation)
            speed_mul = _rng.randf_range(1.0 - speed_variation, 1.0 + speed_variation)

        _phases.append(phase)
        _amplitudes.append(amp)
        _speeds.append(speed_mul)

    _container.size = Vector2(x, max_h)
    # center container inside this Label's rect
    call_deferred("_center_container")

    set_process(true)

func _center_container():
    # On ready and on resize, center the letters container inside this label
    if not _container:
        return
    var parent_size = size
    _container.position = Vector2((parent_size.x - _container.size.x) / 2.0, (parent_size.y - _container.size.y) / 2.0)

func _notification(what):
    if what == NOTIFICATION_RESIZED:
        _center_container()

func _process(delta):
    if not _container:
        return
    _time += delta
    # Apply a vertical sinusoidal offset to each letter. We manipulate
    # the child's `position` directly because we laid them out manually.
    for i in range(_container.get_child_count()):
        var l = _container.get_child(i)
        var base_x = l.position.x
        var base_y = 0.0
        # Use per-letter randomized parameters if available
        var speed_mul = _speeds[i] if _speeds.size() > i else 1.0
        var phase = _phases[i] if _phases.size() > i else (i * phase_offset)
        var amp = _amplitudes[i] if _amplitudes.size() > i else float_amount
        var y = sin(_time * wave_speed * speed_mul + phase) * amp
        l.position = Vector2(base_x, base_y + y)
