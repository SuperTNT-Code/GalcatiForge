# world.gd (attach this to your root world node)
extends Node3D

@onready var world_manager = $WorldManager
@onready var player = $Player

func _ready():
	# Wait for the first frame to ensure everything is loaded
	await get_tree().process_frame
	
	# Position the player above the terrain
	position_player_above_terrain()

func position_player_above_terrain():
	if not player:
		return
		
	# Get the player's XZ position
	var player_x = player.global_position.x
	var player_z = player.global_position.z
	
	# Get the terrain height at this position
	var terrain_height = get_terrain_height(player_x, player_z)
	
	# Position the player above the terrain
	player.global_position.y = terrain_height + 2.0  # 2 units above terrain
	
	print("Player positioned at height: ", terrain_height + 2.0)

func get_terrain_height(x: float, z: float) -> float:
	# Use the same noise function as the terrain generation
	# to ensure consistency
	var base_height = world_manager.noise.get_noise_2d(x, z) * world_manager.terrain_height
	
	# Apply the same biome adjustments as the terrain
	var biome_value = world_manager.biome_noise.get_noise_2d(x, z)
	var temp_value = world_manager.temperature_noise.get_noise_2d(x, z)
	var moisture_value = world_manager.moisture_noise.get_noise_2d(x, z)
	
	# Use the same height adjustment function as the chunks
	return adjust_height_by_biome(base_height, biome_value, temp_value, moisture_value)

func adjust_height_by_biome(base_height: float, biome: float, temperature: float, moisture: float) -> float:
	# This should match the function in your chunk script
	if biome > 0.6:
		return base_height * 1.8 + (temperature * 0.7 * world_manager.terrain_height)
	elif biome > 0.3:
		return base_height * 1.2 + (temperature * 0.4 * world_manager.terrain_height)
	elif biome < -0.6:
		return base_height * 0.2 + (moisture * 0.1 * world_manager.terrain_height) - 5.0
	elif biome < -0.3:
		return base_height * 0.4 + (moisture * 0.2 * world_manager.terrain_height) - 2.0
	else:
		return base_height * 0.5 + (moisture * 0.3 * world_manager.terrain_height)
