class_name BaseState

extends Node2D

enum State {
	SIMULATION,
	INTERACTIVE
}

@export var state: State = State.SIMULATION

func _process(_delta: float) -> void:
	if state == State.INTERACTIVE:
		handle_interactive()

func _physics_process(delta: float) -> void:
	if state == State.SIMULATION:
		handle_simulation(delta)

func handle_simulation(_delta: float) -> void:
	# Placeholder for simulation logic
	pass

func handle_interactive() -> void:
	# Placeholder for interactive logic (e.g., mouse dragging)
	pass

func set_state(new_state: State) -> void:
	state = new_state

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if state == State.SIMULATION:
			set_state(State.INTERACTIVE)
		else:
			set_state(State.SIMULATION)
