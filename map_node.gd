@tool
extends Node2D
class_name MapNode

const DEFAULT_ZOOM = 0.6830133

@export var zoom: bool = false:
	set(val):
		zoom = val
		if not val:
			for child in get_children():
				child.position = child.origin_pos
				child.scale = Vector2(1.0, 1.0)
				

func _process(delta: float) -> void:
	if Engine.is_editor_hint() and zoom:
		var vp := EditorInterface.get_editor_viewport_2d()
		var zoom = vp.get_final_transform().x[0]
		#print(zoom)
		var left_corner = vp.get_final_transform().origin
		var vp_center = (Vector2(vp.size) * 0.5 - left_corner) / zoom #DEFAULT_ZOOM
		for child in get_children():
			if not (child as GroupLayer).statically:
				#var fpar_d_zoom = Vector2.ONE * 0.5 / child.fparallax#/ 5.0#/ zoom 
				#child.position.x = lerp(vp_center.x, child.origin_pos.x, child.parallax.x / 100.0)  #vp_center * fpar_d_zoom  #child.origin_pos +
				#child.position.y = lerp(vp_center.y, child.origin_pos.y, child.parallax.y / 100.0)
				child.position.x = ease(child.fparallax.x, DEFAULT_ZOOM/zoom) * vp_center.x
				child.position.y = ease(child.fparallax.y, DEFAULT_ZOOM/zoom) * vp_center.y
				#         ->>>>>> last print(DEFAULT_ZOOM/zoom)
				#if child.name == " ":
				#	print(child.position, "   zoom: ", DEFAULT_ZOOM/zoom)
				#child.scale.x = 1.0 / zoom / 2
				#child.scale.y = 1.0 / zoom / 20.6830133
				#child.scale = Vector2.ONE / DEFAULT_ZOOM
				var max_par = float(max(child.parallax.x, child.parallax.y))
				#if child.name == " 3":
				#	print(max_par/ 100.0)
				#child.scale.x = lerp(max_par, 1.0, zoom / DEFAULT_ZOOM)
				#child.scale.y = lerp(max_par, 1.0, zoom / DEFAULT_ZOOM)
				print(max_par/100.0)
				child.scale.x = lerp( DEFAULT_ZOOM/ zoom, 1.0,  max_par / 100.0)   # zoom * max_par / 10 
				child.scale.y = child.scale.x
				#child.scale = (Vector2(zoom, zoom) / DEFAULT_ZOOM) #* Vector2(child.parallax) / 100.0 #/ 2.0#Vector2(zoom, zoom) / fpar_d_zoom 
				if child.name == " 3":
					print(child.scale)
				#if fpar_d_zoom.x == 0.0:
					#child.scale.x = 1.0
				#else:
					#child.scale.x = fpar_d_zoom.x 
					#
				#if fpar_d_zoom.y == 0.0:
					#child.scale.y = 1.0
				#else:
					#child.scale.y = fpar_d_zoom.y 

func load_groups(df: MapFile):
	var g_info = df.item_types[MapFile.TYPE_GROUP] #get_type(MapFile.TYPE_GROUP)
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
		tg.parallax = Vector2i(g_p_info.decode_s32(12), g_p_info.decode_s32(16))
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
