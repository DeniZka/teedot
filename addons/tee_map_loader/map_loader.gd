@tool
extends EditorImportPlugin

var map_node: MapNode

const AUTHOR = "author"
const _VERSION = "version"
const CREDITS = "credits"
const LICENSE = "license"
const SETTINGS = "settings"



var name = ""
var images = []
var envilopes = []
var groups = []
var info = {
	AUTHOR: "",
	_VERSION: "",
	CREDITS: "",
	LICENSE: "",
	SETTINGS: []
}

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _get_import_order() -> int:
	return 1
	
func _get_priority() -> float:
	return 3.3

func _get_importer_name():
	return "my.special.plugin"

func _get_visible_name():
	return "DDNet Map File"

func _get_recognized_extensions():
	return ["map"]

func _get_save_extension():
	return "map"

func _get_resource_type():
	return "Map"

func _get_preset_count():
	return 1

func _get_preset_name(preset_index):
	return "Default"

func _get_import_options(path, preset_index):
	return [{"name": "my_option", "default_value": false}]
	
	

func _save_branch(branch_root: Node, save_path: String ) -> int:
	# Set owners of subnodes to root of branch being saved, so PackedScene will include them.
	# But you don't need to do this for subnodes of instances.
	for node in branch_root.get_children():
		_recursive_set_owner(node, branch_root) #get_tree().get_edited_scene_root())
	var packed_scene = PackedScene.new()
	packed_scene.pack(branch_root)
	print("Scene packed")
	return ResourceSaver.save(packed_scene, save_path)


func _recursive_set_owner(node : Node, new_owner : Node):
	node.set_owner(new_owner)
	for child in node.get_children():
		_recursive_set_owner(child, new_owner)

func _import(source_file: String, save_path, options, platform_variants, gen_files):
	return
	var df = MapFile.new(source_file)
	if df.version == 4:
		print("DONE")
	else:
		print("ERROR")
		
	map_node = MapNode.new()
	map_node.load_groups(df)
	map_node.name = source_file.get_file().replace(".map", "")
	

	return _save_branch(map_node, "res://" + map_node.name + ".tscn")
	#var file = FileAccess.open(source_file, FileAccess.READ)
	#if file == null:
	#	return FAILED
	#var mesh = ArrayMesh.new()
	# Заполните сетку данными, считанными из «файла», оставленного в качестве упражнения для читателя.

	#var filename = save_path + "." + _get_save_extension()
	#return ResourceSaver.save(mesh, filename)
	

		
	
func load_images(df: MapFile):
	var images_info = df.get_type(MapFile.TYPE_IMAGE)
	if not images_info:
		return 
		
	for i  in range(0, images_info[MapFile.NUM]):
		var image_item = df.get_item(images_info[MapFile.START] + i)
		var image_info: PackedByteArray = image_item[MapFile.DATA]
		var version = image_info.decode_u32(0)
		var width = image_info.decode_u32(4)
		var height = image_info.decode_u32(8)
		var external = bool(image_info.decode_u32(12))
		var name = image_info.decode_s32(16)
		var data = image_info.decode_s32(20)
		
		var im_name: String = df.get_data(name).get_string_from_utf8()
		if external:
			pass #FIXME: find external image
		else:
			var fn: String = "res://images/internal/" + df.get_data(name).get_string_from_ascii() + ".png"
			if not FileAccess.file_exists(fn):
				var img: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, df.get_data(data))
				img.save_png(fn)
			
			#img.set("name", df.get_data(name))
			#img.set("external", bool(external))
				images.push_back(img)
