extends Node3D

# Player movement properties
@export var move_speed: float = 5.0
@export var jump_force: float = 4.5
@export var gravity: float = 9.8

# Camera control properties
@export var camera_sensitivity: float = 0.003
@export var camera_pitch_min: float = -60.0
@export var camera_pitch_max: float = -10.0

# Node References
@onready var character_body: CharacterBody3D = $CharacterBody
@onready var camera_pivot: Node3D = $CameraPivot

# Camera rotation state
var camera_pitch: float = 0.0 # Vertical look (up/down)
var camera_yaw: float = 0.0   # Horizontal look (left/right)

func _ready():
	# Capture the mouse so it's not visible and is locked to the center of the window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Adjust yaw and pitch based on mouse movement
		camera_yaw -= event.relative.x * camera_sensitivity
		camera_pitch -= event.relative.y * camera_sensitivity
		# Clamp the vertical look to avoid flipping the camera
		camera_pitch = clamp(camera_pitch, deg_to_rad(camera_pitch_min), deg_to_rad(camera_pitch_max))
		
		# Apply the rotations
		global_rotation.y = camera_yaw # Rotate the entire player left/right
		camera_pivot.rotation.x = camera_pitch # Tilt the camera pivot up/down

func _physics_process(delta):
	# Get player input for movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply gravity
	if not character_body.is_on_floor():
		character_body.velocity.y -= gravity * delta
		
	# Handle jumping
	if Input.is_action_just_pressed("jump") and character_body.is_on_floor():
		character_body.velocity.y = jump_force
	
	# Apply horizontal movement (on the ground or in air)
	if direction:
		character_body.velocity.x = direction.x * move_speed
		character_body.velocity.z = direction.z * move_speed
	else:
		# Apply friction or damping when no input is given
		character_body.velocity.x = move_toward(character_body.velocity.x, 0, move_speed)
		character_body.velocity.z = move_toward(character_body.velocity.z, 0, move_speed)
	
	# Move the character
	character_body.move_and_slide()
