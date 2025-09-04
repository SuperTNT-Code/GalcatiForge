extends CharacterBody3D

@export_group("Movement Settings")
@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var acceleration := 10.0
@export var air_control := 0.3
@export var backwards_speed_multiplier := 0.7

@export_group("Camera Settings")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.18

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var _camera_input_direction := Vector2.ZERO
var _current_speed := walk_speed

@onready var _camera_pivot: Node3D = $CameraPivot

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	# Check for mouse motion events when mouse is captured
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_camera_input_direction = event.relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	# Handle camera rotation (only rotate camera, not the character)
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI/2.0, PI/2.0)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	
	# Reset camera input
	_camera_input_direction = Vector2.ZERO
	
	# Handle sprint
	_current_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Calculate movement direction relative to character's orientation (not camera)
	var direction = Vector3.ZERO
	direction = transform.basis.z * input_dir.y  # Forward/backward
	direction += transform.basis.x * input_dir.x  # Left/right
	direction.y = 0
	direction = direction.normalized()
	
	# Calculate effective speed (slower when moving backwards)
	var effective_speed = _current_speed
	
	# Check if we're moving backwards (negative input on the forward/back axis)
	if input_dir.y < 0:  # Negative y means moving backwards
		effective_speed *= backwards_speed_multiplier
	
	# Apply movement
	if direction:
		var control = acceleration if is_on_floor() else acceleration * air_control
		velocity.x = move_toward(velocity.x, direction.x * effective_speed, control)
		velocity.z = move_toward(velocity.z, direction.z * effective_speed, control)
	else:
		# Apply friction when not moving
		var friction = acceleration if is_on_floor() else acceleration * air_control
		velocity.x = move_toward(velocity.x, 0, friction)
		velocity.z = move_toward(velocity.z, 0, friction)
	
	move_and_slide()
