extends Node3D

# Configuration - adjust these in the Inspector
@export var chunk_size := 16
@export var view_distance := 3
@export var terrain_height := 10.0
@export var noise_frequency := 0.03
@export var noise_octaves := 2

# Noise variables - make sure these are declared
var noise: FastNoiseLite
var biome_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var moisture_noise: FastNoiseLite

# References
var player: CharacterBody3D
var loaded_chunks := {}
var chunk_scene = preload("res://world/chunk.tscn")

# Track player's current chunk
var current_player_chunk := Vector2()

func _ready():
	# Set up the noise generator
	setup_noise()
	
	# Find the player
	find_player()
	
	# Generate initial chunks
	if player:
		update_chunks()

func _process(_delta):
	# Only update chunks if player has moved to a new chunk
	if player:
		var player_chunk = get_chunk_coords(player.global_position)
		if player_chunk != current_player_chunk:
			current_player_chunk = player_chunk
			update_chunks()

func setup_noise():
	# Terrain noise
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = noise_frequency
	noise.fractal_octaves = noise_octaves
	
	# Biome noise
	biome_noise = FastNoiseLite.new()
	biome_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	biome_noise.seed = randi() + 100
	biome_noise.frequency = 0.005
	
	# Temperature noise
	temperature_noise = FastNoiseLite.new()
	temperature_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	temperature_noise.seed = randi() + 200
	temperature_noise.frequency = 0.01
	
	# Moisture noise
	moisture_noise = FastNoiseLite.new()
	moisture_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	moisture_noise.seed = randi() + 300
	moisture_noise.frequency = 0.01

func find_player():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("WorldManager: No player found in group 'player'")

func update_chunks():
	if not player:
		return
		
	var player_chunk = get_chunk_coords(player.global_position)
	var chunks_to_keep = {}
	
	for x in range(player_chunk.x - view_distance, player_chunk.x + view_distance + 1):
		for z in range(player_chunk.y - view_distance, player_chunk.y + view_distance + 1):
			var chunk_coord = Vector2(x, z)
			chunks_to_keep[chunk_coord] = true
			
			if not loaded_chunks.has(chunk_coord):
				load_chunk(x, z)
	
	for chunk_coord in loaded_chunks.keys():
		if not chunks_to_keep.has(chunk_coord):
			unload_chunk(chunk_coord)

func get_chunk_coords(world_position: Vector3) -> Vector2:
	var x = floor(world_position.x / chunk_size)
	var z = floor(world_position.z / chunk_size)
	return Vector2(x, z)

func load_chunk(x: int, z: int):
	var new_chunk = chunk_scene.instantiate()
	add_child(new_chunk)
	
	# Make sure this matches the initialize function signature in chunk.gd
	new_chunk.initialize(x, z, chunk_size, noise, biome_noise, temperature_noise, moisture_noise, terrain_height)
	
	loaded_chunks[Vector2(x, z)] = new_chunk
	print("Loaded chunk: ", x, ", ", z)

func unload_chunk(chunk_coord: Vector2):
	var chunk = loaded_chunks[chunk_coord]
	if chunk:
		chunk.queue_free()
	loaded_chunks.erase(chunk_coord)
	print("Unloaded chunk: ", chunk_coord.x, ", ", chunk_coord.y)
