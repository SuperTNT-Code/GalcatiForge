# world.gd
extends Node3D

@export var chunk_size := 16
@export var render_distance := 3
@export var terrain_height := 32

var noise: FastNoiseLite
var player_ref: Node3D
var active_chunks := {}
var chunk_scene = preload("res://world/chunk.tscn")

func _ready():
	# Initialize noise
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	
	# Find player reference
	player_ref = get_tree().get_first_node_in_group("player")
	
	# Initial chunk generation
	update_chunks()

# Convert world position to chunk coordinates
func world_to_chunk(position: Vector3) -> Vector2:
	var x = floor(position.x / chunk_size)
	var z = floor(position.z / chunk_size)
	return Vector2(x, z)

# Convert chunk coordinates to world position (center of chunk)
func chunk_to_world(chunk_coord: Vector2) -> Vector3:
	var x = chunk_coord.x * chunk_size + chunk_size / 2.0
	var z = chunk_coord.y * chunk_size + chunk_size / 2.0
	return Vector3(x, 0, z)

func update_chunks():
	if not player_ref:
		return
		
	# Get player's current chunk
	var player_chunk = world_to_chunk(player_ref.global_position)
	
	# Determine which chunks should be active
	var chunks_to_keep = {}
	
	for x in range(player_chunk.x - render_distance, player_chunk.x + render_distance + 1):
		for z in range(player_chunk.y - render_distance, player_chunk.y + render_distance + 1):
			var chunk_coord = Vector2(x, z)
			chunks_to_keep[chunk_coord] = true
			
			# Load chunk if it doesn't exist
			if not active_chunks.has(chunk_coord):
				load_chunk(chunk_coord)
	
	# Unload chunks outside render distance
	for chunk_coord in active_chunks.keys():
		if not chunks_to_keep.has(chunk_coord):
			unload_chunk(chunk_coord)

func load_chunk(chunk_coord: Vector2):
	var new_chunk = chunk_scene.instantiate()
	new_chunk.initialize(chunk_coord, chunk_size, noise, terrain_height)
	add_child(new_chunk)
	active_chunks[chunk_coord] = new_chunk

func unload_chunk(chunk_coord: Vector2):
	var chunk = active_chunks[chunk_coord]
	if chunk:
		chunk.queue_free()
	active_chunks.erase(chunk_coord)

var last_player_chunk: Vector2

func _process(_delta):
	if not player_ref:
		return
		
	var current_chunk = world_to_chunk(player_ref.global_position)
	
	# Only update if player moved to a new chunk
	if current_chunk != last_player_chunk:
		update_chunks()
		last_player_chunk = current_chunk
