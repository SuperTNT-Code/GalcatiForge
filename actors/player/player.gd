extends CharacterBody3D

# Player movement properties
@export var move_speed: float = 5.0
@export var jump_force: float = 4.5
@export var acceleration: float = 10.0 # How quickly the player gets to full speed
@export var air_acceleration: float = 2.0  # Slower acceleration in the air
@export var gravity: float = 9.8

# Camera control properties
@export var camera_sensitivity: float = 0.003
@export var camera_pitch_max_degrees: float = 60.0
@export var camera_pitch_min_degrees: float = -70.0

# Node References
# The CameraPivot should be a child of this CharacterBody3D
@onready var camera_pivot: Node3D = $CameraPivot

# Camera rotation state
var camera_pitch: float = 0.0 # Vertical look (up/down)

func _ready():
	# Capture the mouse so it's not visible and is locked to the center of the window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate the entire player body left/right (yaw)
		rotate_y(-event.relative.x * camera_sensitivity)
		
		# Adjust camera pitch (up/down)
		camera_pitch -= event.relative.y * camera_sensitivity
		# Clamp the vertical look to avoid flipping the camera
		camera_pitch = clamp(camera_pitch, deg_to_rad(camera_pitch_min_degrees), deg_to_rad(camera_pitch_max_degrees))
		
		# Apply the pitch rotation only to the camera pivot
		camera_pivot.rotation.x = camera_pitch

func _physics_process(delta):
	# --- Gravity ---
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# --- Jumping ---
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	
	# --- Movement ---
	# Get player input for movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Use the CharacterBody's own transform basis to get the correct world direction
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Choose acceleration based on whether we are on the ground or in the air
	var current_accel = acceleration if is_on_floor() else air_acceleration
	
	# Create a target velocity
	var target_velocity = direction * move_speed
	
	# Use lerp (linear interpolation) for smooth acceleration and deceleration
	# We only want to affect the horizontal (x, z) plane
	velocity.x = lerp(velocity.x, target_velocity.x, current_accel * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, current_accel * delta)
	
	# --- Finalize Movement ---
	# This function applies the velocity and handles collisions
	move_and_slide()
