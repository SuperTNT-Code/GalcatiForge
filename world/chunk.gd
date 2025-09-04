extends StaticBody3D

# Node references
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# Chunk data
var chunk_coord: Vector2
var chunk_size: int
var noise: FastNoiseLite
var biome_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var max_height: float

func initialize(x: int, z: int, size: int, noise_ref: FastNoiseLite, 
			   biome_noise_ref: FastNoiseLite, temp_noise_ref: FastNoiseLite, 
			   moisture_noise_ref: FastNoiseLite, height: float):
	chunk_coord = Vector2(x, z)
	chunk_size = size
	noise = noise_ref
	biome_noise = biome_noise_ref
	temperature_noise = temp_noise_ref
	moisture_noise = moisture_noise_ref
	max_height = height
	
	# Position the chunk in the world
	position = Vector3(x * size, 0, z * size)
	
	# Generate the terrain
	generate_terrain()

func generate_terrain():
	# Create a subdivided plane for more detail
	var subdivisions = 8
	var vertices = []
	var indices = []
	
	# Generate vertices with height from noise and biomes
	for z in range(subdivisions + 1):
		for x in range(subdivisions + 1):
			# Calculate local position within chunk
			var local_x = (x / float(subdivisions)) * chunk_size - chunk_size / 2.0
			var local_z = (z / float(subdivisions)) * chunk_size - chunk_size / 2.0
			
			# Calculate world position for noise sampling
			var world_x = position.x + local_x
			var world_z = position.z + local_z
			
			# Get base height from noise
			var base_height = noise.get_noise_2d(world_x, world_z) * max_height
			
			# Get biome information
			var biome_value = biome_noise.get_noise_2d(world_x, world_z)
			var temp_value = temperature_noise.get_noise_2d(world_x, world_z)
			var moisture_value = moisture_noise.get_noise_2d(world_x, world_z)
			
			# Adjust height based on biome
			var height = adjust_height_by_biome(base_height, biome_value, temp_value, moisture_value)
			
			# Add vertex
			vertices.append(Vector3(local_x, height, local_z))
	
	# Generate indices for triangles
	for z in range(subdivisions):
		for x in range(subdivisions):
			# Calculate indices for the current quad
			var top_left = z * (subdivisions + 1) + x
			var top_right = top_left + 1
			var bottom_left = (z + 1) * (subdivisions + 1) + x
			var bottom_right = bottom_left + 1
			
			# Add first triangle
			indices.append(top_left)
			indices.append(bottom_left)
			indices.append(top_right)
			
			# Add second triangle
			indices.append(top_right)
			indices.append(bottom_left)
			indices.append(bottom_right)
	
	# Create the mesh
	var array_mesh = ArrayMesh.new()
	var surface_tool = SurfaceTool.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Add all vertices
	for vertex in vertices:
		surface_tool.add_vertex(vertex)
	
	# Add all indices
	for index in indices:
		surface_tool.add_index(index)
	
	# Generate normals for proper lighting
	surface_tool.generate_normals()
	
	# Create the final mesh
	array_mesh = surface_tool.commit()
	mesh_instance.mesh = array_mesh
	
	# Create collision shape
	create_collision_shape()

func create_collision_shape():
	# Create a heightmap shape for accurate collision
	var heightmap_shape = HeightMapShape3D.new()
	
	# We need to create height data for the collision shape
	var width = 9  # Should match your subdivisions + 1
	var depth = 9
	var heightmap_data = PackedFloat32Array()
	
	# Generate height data using the same method as the terrain
	for z in range(depth):
		for x in range(width):
			# Calculate local position within chunk
			var local_x = (x / float(width-1)) * chunk_size - chunk_size / 2.0
			var local_z = (z / float(depth-1)) * chunk_size - chunk_size / 2.0
			
			# Calculate world position for noise sampling
			var world_x = position.x + local_x
			var world_z = position.z + local_z
			
			# Get base height from noise
			var base_height = noise.get_noise_2d(world_x, world_z) * max_height
			
			# Get biome information
			var biome_value = biome_noise.get_noise_2d(world_x, world_z)
			var temp_value = temperature_noise.get_noise_2d(world_x, world_z)
			var moisture_value = moisture_noise.get_noise_2d(world_x, world_z)
			
			# Adjust height based on biome
			var height = adjust_height_by_biome(base_height, biome_value, temp_value, moisture_value)
			
			# Add to heightmap data
			heightmap_data.append(height)
	
	# Set the heightmap data
	heightmap_shape.map_width = width
	heightmap_shape.map_depth = depth
	heightmap_shape.map_data = heightmap_data
	
	# Apply the collision shape
	collision_shape.shape = heightmap_shape
	collision_shape.position = Vector3(0, 0, 0)  # Center the collision

func adjust_height_by_biome(base_height: float, biome: float, temperature: float, moisture: float) -> float:
	# Simple biome-based height adjustments
	if biome > 0.6:
		# Mountain biome - higher and more varied
		return base_height * 1.8 + (temperature * 0.7 * max_height)
	elif biome > 0.3:
		# Hills biome - moderate height
		return base_height * 1.2 + (temperature * 0.4 * max_height)
	elif biome < -0.6:
		# Deep ocean biome - very low
		return base_height * 0.2 + (moisture * 0.1 * max_height) - 5.0
	elif biome < -0.3:
		# Shallow water biome - low
		return base_height * 0.4 + (moisture * 0.2 * max_height) - 2.0
	else:
		# Plains biome - mostly flat with slight variations
		return base_height * 0.5 + (moisture * 0.3 * max_height)
