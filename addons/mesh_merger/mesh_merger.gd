@tool
extends MeshInstance3D
class_name MeshMerger

var result_mesh:ArrayMesh
var result_mesh_material:Material


@export  var collision_parent_path:NodePath
@onready var collision_parent:Node


@export var btn_merge_meshes:bool = false:
	set(value):
		merge_meshes()

@export var btn_clean_meshes:bool = false:
	set(value):
		clean_meshes()
		
		
@export var btn_generate_lods:bool = false:
	set(value):
		generate_lods()


@export var toggle_children_visibility:bool = false:
	get:
		return toggle_children_visibility
	set(value):
		toggle_children_visibility = value
		set_toggle_children_visibility(value)

@export var delete_child_meshes_on_play:bool = false:
	set(value):
		delete_child_meshes_on_play = value
	get:
		return delete_child_meshes_on_play


func generate_lods():
	if mesh == null:
		printerr("Mesh has no surface to create LODs from.")
		return

	var _importer_mesh := ImporterMesh.new()
	var surface_array := mesh.surface_get_arrays(0)
	_importer_mesh.clear()
	_importer_mesh.add_surface(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	_importer_mesh.generate_lods(30, 60, [])
	mesh = _importer_mesh.get_mesh()

# warning-ignore:unused_argument
func merge_meshes() -> void:
	if !Engine.is_editor_hint():
		return

	if result_mesh != null:
		result_mesh.clear_surfaces()
	
	if collision_parent_path != null:
		collision_parent = get_node(collision_parent_path)
		clean_collisions()

	var _surface_tool := SurfaceTool.new()
#	var _importer_mesh:= ImporterMesh.new()

	for node in get_children():
		if node is MeshInstance3D:
			_surface_tool.append_from(node.mesh, 0, node.transform)
			grab_material(node)
			generate_collisions(node)

		result_mesh = _surface_tool.commit()
	
	set_toggle_children_visibility(false)
	self.mesh = result_mesh
	self.material_override = result_mesh_material

# warning-ignore:unused_argument
func clean_meshes() -> void:
	if !Engine.is_editor_hint():
		return

	if collision_parent_path:
		collision_parent = get_node(collision_parent_path)

	mesh = ArrayMesh.new()
	clean_collisions()
	set_toggle_children_visibility(true)


func grab_material(node) -> void:
	if node.get_active_material(0) != null:
		result_mesh_material = node.get_active_material(0)
	elif node.mesh._surface_get_material(0) != null:
		result_mesh_material = node.mesh._surface_get_material(0)

func generate_collisions(node) -> void:
	if collision_parent == null or collision_parent_path == null:
		return
	for child in node.get_children():
		if child is StaticBody3D and child.get_child_count() > 0:
			for grandchild in child.get_children():
				if grandchild is CollisionShape3D:
					var new_col := CollisionShape3D.new()
					new_col.global_transform = child.global_transform
					collision_parent.add_child(new_col)
					new_col.shape = grandchild.shape
					new_col.set_owner(get_tree().get_edited_scene_root())

func clean_collisions() -> void:
	if collision_parent == null or collision_parent_path == null:
		return
	if collision_parent.get_child_count() > 0:
		for child in collision_parent.get_children():
			child.queue_free()

func set_toggle_children_visibility(value) -> void:
	for node in get_children():
		if node is MeshInstance3D:
			node.set_visible(value)

func _ready() -> void:
	if delete_child_meshes_on_play:
		for node in get_children():
			if node is MeshInstance3D:
				print("children deleted")
				node.queue_free()
