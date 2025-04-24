@tool
extends Node2D
class_name MapNode

@export var zoom: bool = false:
	set(val):
		if not val:
			for child in get_children():
				child.position = child.origin_pos

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if zoom:
			var vp := EditorInterface.get_editor_viewport_2d()
			var v = vp.size / 2
			for child in get_children():
				child.position = (Vector2(v) -  vp.get_final_transform().origin)  * (Vector2.ONE - Vector2(child.paraX, child.paraY) / 100)


func load_groups(df: MapFile):
	var g_info = df.get_type(MapFile.TYPE_GROUP)
	if not g_info:
		return
	for i in range(0, g_info[MapFile.NUM]):
		print("group ", i, " of ", g_info[MapFile.NUM] - 1)
		var g_item = df.get_item(g_info[MapFile.START] + i)
		var g_p_info: PackedByteArray = g_item[MapFile.DATA]
		var tg = GroupLayer.new()
		add_child(tg)
		
		
		tg.version = g_p_info.decode_u32(0)
		var child_pos = -2.0 * Vector2( g_p_info.decode_s32(4), g_p_info.decode_s32(8) )
		tg.origin_pos = child_pos
		tg.position = child_pos
		tg.paraX = g_p_info.decode_s32(12)
		tg.paraY = g_p_info.decode_s32(16)
		tg.startLayer = g_p_info.decode_u32(20)
		tg.numLayers = g_p_info.decode_u32(24)
		tg.clipping = bool(g_p_info.decode_u32(28))

		# version 2 extension
		tg.clipX = g_p_info.decode_u32(32)
		tg.clipY = g_p_info.decode_u32(36)
		tg.clipW = g_p_info.decode_u32(40)
		tg.clipH = g_p_info.decode_u32(44)
		
		if tg.version >= 3:
			var _name = DDString.unpack(g_p_info.slice(48, 48+12))
			if not _name:
				tg.name = " "
			else:
				tg.name = _name
			print(">", _name)
		tg.load_layers(df)
		
	print("Groups Loaded")
