@icon("res://Art/Icons/FSMSprite.png")
extends Node
class_name FiniteStateMachine

var states: Dictionary = {}
var current_state: State
@export var initial_state: State

#NOTE This is a generic finite_state_machine, it handles all states, changes to this code will affect
	# everything that uses a state machine!

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_transition.connect(change_state)

	if initial_state:
		initial_state.Enter()
		current_state = initial_state

#Call the current states update function continuosly
func _process(delta: float) -> void:
	if current_state:
		current_state.Update(delta)

#region State Management
#Use force_change_state cautiously, it immediately switches to a state regardless of any transitions.
#This is used to force us into a 'death state' when killed
func force_change_state(new_state: String) -> void:
	var new_state_node: State = states.get(new_state.to_lower())
	
	if not new_state_node:
		push_warning("%s does not exist in the dictionary of states" % new_state)
		return
	
	if current_state == new_state_node:
		# No-op: already in this state.
		return
		
	#NOTE Calling exit like so: (current_state.Exit()) may cause warnings when flushing queries, like when the enemy is being removed after death. 
	#call_deferred is safe and prevents this from occuring. We get the Exit function from the state as a callable and then call it in a thread-safe manner
	if current_state:
		var exit_callable = Callable(current_state, "Exit")
		exit_callable.call_deferred()
	
	new_state_node.Enter()
	
	current_state = new_state_node
	
func change_state(source_state: State, new_state_name: String) -> void:
	if source_state != current_state:
		#print("Invalid change_state trying from: " + source_state.name + " but currently in: " + current_state.name)
		#This typically only happens when trying to switch from death state following a force_change
		return
	
	var new_state: State = states.get(new_state_name.to_lower())
	if not new_state:
		push_warning("New state is empty: %s" % new_state_name)
		return
		
	if current_state:
		# Prefer deferred Exit for consistency/safety with node teardown.
		var exit_callable = Callable(current_state, "Exit")
		exit_callable.call_deferred()
		
	new_state.Enter()
	
	current_state = new_state

#endregion
