extends StaticBody3D

var chunk_coord: Vector2
var chunk_size: int
var terrain_height: int
var noise: FastNoiseLite

func initialize(coord: Vector2, size: int, noise_ref: FastNoiseLite, height: int):
	chunk_coord = coord
	chunk_size = size
	noise = noise_ref
	terrain_height = height
	generate_terrain()

func generate_terrain():
	# Create a mesh for this chunk
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_width = chunk_size / 2
	plane_mesh.subdivide_depth = chunk_size / 2
	
	# Create a mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = plane_mesh
	
	# Position the chunk correctly
	global_position = Vector3(chunk_coord.x * chunk_size, 0, chunk_coord.y * chunk_size)
	
	# Generate height data using noise
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(mesh_instance.mesh, 0)
	
	# This is where you'd modify vertices based on noise
	# You'll need to implement vertex displacement here
	
	add_child(mesh_instance)
