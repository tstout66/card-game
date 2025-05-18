extends "res://scripts/base_state.gd"

@export var mass: float = 1.0
@export var thrust: float = 10.0

var velocity: Vector2 = Vector2.ZERO

func handle_simulation(delta: float) -> void:
	# Apply upward thrust as a force
	var force: Vector2 = Vector2(0, -thrust / mass)
	velocity += force * delta

	# Update position based on velocity
	position += velocity * delta

var _dragging := false


func _ready() -> void:
	# Connect the input_event signal from Area2D if it exists
	if has_node("Area2D"):
		$Area2D.connect("input_event", Callable(self, "_on_area2d_input_event"))
	# Add this card to the 'cards' group for snapping
	add_to_group("cards")

func _process(_delta: float) -> void:
	# If dragging, update position to follow mouse and snap to other cards
	if _dragging and state == State.INTERACTIVE:
		var mouse_pos: Vector2 = get_global_mouse_position()
		position = mouse_pos

		# Snap logic
		var my_shape = $Area2D.get_node("CollisionShape2D").shape
		if typeof(my_shape) != TYPE_NIL and my_shape is RectangleShape2D:
			var my_rect: Rect2        = Rect2(global_position - my_shape.size * 0.5, my_shape.size)
			var snap_threshold: float = 20.0 # pixels
			for card in get_tree().get_nodes_in_group("cards"):
				if card == self:
					continue
				if not card.has_node("Area2D/CollisionShape2D"):
					continue
				var other_shape = card.get_node("Area2D/CollisionShape2D").shape
				if typeof(other_shape) == TYPE_NIL or not (other_shape is RectangleShape2D):
					continue
				var other_rect: Rect2 = Rect2(card.global_position - other_shape.size * 0.5, other_shape.size)

				# Check each edge for proximity and snap if close
				# Left edge
				if abs(my_rect.position.x - (other_rect.position.x + other_rect.size.x)) < snap_threshold:
					position.x = card.global_position.x + other_shape.size.x / 2 + my_shape.size.x / 2
				# Right edge
				elif abs((my_rect.position.x + my_rect.size.x) - other_rect.position.x) < snap_threshold:
					position.x = card.global_position.x - other_shape.size.x / 2 - my_shape.size.x / 2
				# Top edge
				if abs(my_rect.position.y - (other_rect.position.y + other_rect.size.y)) < snap_threshold:
					position.y = card.global_position.y + other_shape.size.y / 2 + my_shape.size.y / 2
				# Bottom edge
				elif abs((my_rect.position.y + my_rect.size.y) - other_rect.position.y) < snap_threshold:
					position.y = card.global_position.y - other_shape.size.y / 2 - my_shape.size.y / 2

# This function will be called when the Area2D receives an input event
func _on_area2d_input_event(_viewport, event, _shape_idx) -> void:
	# Only allow interaction if in INTERACTIVE state
	if state == State.INTERACTIVE:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
			else:
				_dragging = false
