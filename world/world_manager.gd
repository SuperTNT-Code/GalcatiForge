extends Node3D

# Configuration - adjust these in the Inspector
@export var chunk_size := 16
@export var view_distance := 3  # Creates a 7×7 grid (view_distance*2 + 1)
@export var terrain_height := 10.0
@export var noise_frequency := 0.05
@export var noise_octaves := 4

# References
var player: CharacterBody3D
var noise: FastNoiseLite
var loaded_chunks := {}
var chunk_scene = preload("res://world/chunk.tscn")

# Track player's current chunk
var current_player_chunk := Vector2()

# Add to world_manager.gd
func position_player_above_terrain():
	if not player:
		return
	
	# Get the height at the player's position
	var player_pos = player.global_position
	var terrain_height = get_terrain_height(player_pos.x, player_pos.z)
	
	# Position the player above the terrain
	player.global_position.y = terrain_height + 2.0  # 2 units above the terrain

func get_terrain_height(x: float, z: float) -> float:
	# Sample the noise at the given position
	return noise.get_noise_2d(x, z) * terrain_height

# Call this after generating chunks in _ready()
func _ready():
	setup_noise()
	find_player()
	if player:
		update_chunks()
		# Wait a frame for chunks to generate, then position player
		await get_tree().process_frame
		position_player_above_terrain()

func _process(_delta):
	# Only update chunks if player has moved to a new chunk
	if player:
		var player_chunk = get_chunk_coords(player.global_position)
		if player_chunk != current_player_chunk:
			current_player_chunk = player_chunk
			update_chunks()

func setup_noise():
	# Create and configure the noise generator
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.01  # Lower frequency for larger, smoother features
	noise.fractal_octaves = 2  # Fewer octaves for less detail
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0

func find_player():
	# Look for the player node
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("WorldManager: No player found in group 'player'")

func update_chunks():
	# Get player's current chunk position
	var player_chunk = get_chunk_coords(player.global_position)
	
	# Determine which chunks should be loaded
	var chunks_to_keep = {}
	
	# Create chunks in a grid around the player
	for x in range(player_chunk.x - view_distance, player_chunk.x + view_distance + 1):
		for z in range(player_chunk.y - view_distance, player_chunk.y + view_distance + 1):
			var chunk_coord = Vector2(x, z)
			chunks_to_keep[chunk_coord] = true
			
			# Load chunk if it doesn't exist
			if not loaded_chunks.has(chunk_coord):
				load_chunk(x, z)
	
	# Unload chunks that are too far away
	for chunk_coord in loaded_chunks.keys():
		if not chunks_to_keep.has(chunk_coord):
			unload_chunk(chunk_coord)

func get_chunk_coords(world_position: Vector3) -> Vector2:
	# Convert world position to chunk coordinates
	var x = floor(world_position.x / chunk_size)
	var z = floor(world_position.z / chunk_size)
	return Vector2(x, z)

func load_chunk(x: int, z: int):
	# Create a new chunk instance
	var new_chunk = chunk_scene.instantiate()
	add_child(new_chunk)
	
	# Initialize the chunk with position and noise
	new_chunk.initialize(x, z, chunk_size, noise, terrain_height)
	
	# Store reference to the chunk
	loaded_chunks[Vector2(x, z)] = new_chunk
	
	print("Loaded chunk: ", x, ", ", z)

func unload_chunk(chunk_coord: Vector2):
	# Remove a chunk from the world
	var chunk = loaded_chunks[chunk_coord]
	if chunk:
		chunk.queue_free()
	loaded_chunks.erase(chunk_coord)
	
	print("Unloaded chunk: ", chunk_coord.x, ", ", chunk_coord.y)
