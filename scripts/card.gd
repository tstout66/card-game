extends BaseState

@export var mass: float = 1.0
@export var thrust: float = 10.0

var velocity: Vector2 = Vector2.ZERO
var _dragging := false
var _drag_offset := Vector2.ZERO
var parent_card: Node2D

func handle_simulation(delta: float) -> void:
	# Apply upward thrust as a force
	var force: Vector2 = Vector2(0, -thrust / mass)
	velocity += force * delta

	# Update position based on velocity
	position += velocity * delta

func handle_interactive() -> void:
	if _dragging:
		position = get_global_mouse_position() + _drag_offset

func _ready() -> void:
	# Connect the input_event signal from Area2D if it exists
	parent_card = get_parent()
	var area: Node = get_node_or_null("Area2D")
	if area:
		area.input_event.connect(_on_area_input_event)

	# Add this card to the 'cards' group for snapping
	add_to_group("cards")

func _process(_delta: float) -> void:
	# If dragging, update position to follow mouse
	if _dragging and state == State.INTERACTIVE:
		parent_card.position = get_global_mouse_position() + _drag_offset

func _on_area_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				# Calculate the offset to maintain the relative position when dragging
				_drag_offset = position - get_global_mouse_position()
			else:
				_dragging = false
				# Apply snapping when the card is released
				snap_to_nearest_card()

# Find the nearest card to snap to
func find_nearest_snap_position() -> Dictionary:
	var snap_data: Dictionary = {
		"should_snap": false,
		"position": Vector2.ZERO,
		"snap_type": "", # "x" or "y"
	}
	
	var nearest_distance: float = 50.0 # Snap threshold distance
	var cards: Array[Node]      = get_tree().get_nodes_in_group("cards")
	
	for card in cards:
		if card == self:
			continue # Skip self

		var x_distance = abs(position.x - card.position.x)
		var y_distance = abs(position.y - card.position.y)
		
		# Check if we should snap to X coordinate (left or right)
		if y_distance < nearest_distance && x_distance > nearest_distance:
			snap_data.should_snap = true
			snap_data.position = Vector2(position.x, card.position.y)
			snap_data.snap_type = "y"
			nearest_distance = y_distance
		
		# Check if we should snap to Y coordinate (above or below)
		if x_distance < nearest_distance && y_distance > nearest_distance:
			snap_data.should_snap = true
			snap_data.position = Vector2(card.position.x, position.y)
			snap_data.snap_type = "x"
			nearest_distance = x_distance
	
	return snap_data

# Apply snapping to the nearest card
func snap_to_nearest_card() -> void:
	var snap_data: Dictionary = find_nearest_snap_position()
	
	if snap_data.should_snap:
		position = snap_data.position

	# Alternative collision-based snap logic
	var area: Node = get_node_or_null("Area2D")
	if area and area.has_node("CollisionShape2D"):
		var my_shape = area.get_node("CollisionShape2D").shape
		if my_shape is RectangleShape2D:
			var my_rect: Rect2 = Rect2(global_position - my_shape.size * 0.5, my_shape.size)
			var snap_threshold: float = 20.0 # pixels
			for card in get_tree().get_nodes_in_group("cards"):
				if card == self:
					continue
				if not card.has_node("Area2D/CollisionShape2D"):
					continue
				var other_shape = card.get_node("Area2D/CollisionShape2D").shape
				if not (other_shape is RectangleShape2D):
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
