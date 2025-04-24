extends Node2D
class_name GroupLayer

const LAYER_TYPE_INVALID = 0
const LAYER_TYPE_TILES = 2
const LAYER_TYPE_QUADS = 3
const LAYER_TYPE = 5

@export var version: int
@export var origin_pos: Vector2
@export var ffX: int
@export var offY: int
@export var paraX: int
@export var paraY: int
@export var startLayer: int
@export var numLayers: int
@export var clipping: bool

# version 2 extension
@export var clipX: int
@export var clipY: int
@export var clipW: int
@export var clipH: int

var empty_texture = load("res://default/images/empty.png")

func load_layers(df: MapFile):
	var type_info = df.get_type(MapFile.TYPE_LAYER)
	for i in range(startLayer, startLayer + numLayers):
		#print("Layer ", i, " to ", startLayer + numLayers - 1)
		var layer_item = df.get_item(type_info[MapFile.START] + i)
		#print("li", layer_item)
		var layer_info = StreamPeerBuffer.new()
		layer_info.data_array = layer_item[MapFile.DATA]#df.get_data(type_info[MapFile.DATA])
		var varsion = layer_info.get_u32()
		var layer_type = layer_info.get_u32()
		var flags = layer_info.get_u32()
		if layer_type == LAYER_TYPE_TILES:
			print("TILE LAYER")
			var tile_layer_version = layer_info.get_u32()
			var tile_layer_width = layer_info.get_u32()
			var tile_layer_height = layer_info.get_u32()
			var tile_layer_flags = layer_info.get_u32()
			var r = layer_info.get_u32() / 255.0
			var g = layer_info.get_u32() / 255.0
			var b = layer_info.get_u32() / 255.0
			var a = layer_info.get_u32() / 255.0
			var mod_color = Color(r, g, b, a)
			var tile_layer_color_env = layer_info.get_u32()
			var tile_layer_env_offset = layer_info.get_u32()
			var tile_layer_image = layer_info.get_32()
			var tile_layer_data = layer_info.get_u32()
			var tile_layer_name = " "
			if tile_layer_version >= 3:
				var _name = DDString.unpack(PackedByteArray(layer_info.get_data(12)[1]))
				if _name:
					tile_layer_name = _name
			print(">> ", tile_layer_name)
				
			if tile_layer_flags != TileLayerDefault.GAME and tile_layer_flags != TileLayerDefault.TILES:
				var data_tele = layer_info.get_u32()
				var data_speedup = layer_info.get_u32()
				var data_front = layer_info.get_u32()
				var data_switch = layer_info.get_u32()
				var data_tune = layer_info.get_u32()
				
			if tile_layer_flags == TileLayerDefault.TILES:
				var tile_layer = TileLayerDefault.new()
				tile_layer.modulate = mod_color
				tile_layer.name = tile_layer_name
				tile_layer.width = tile_layer_width
				tile_layer.height = tile_layer_height
				
				var s: StreamPeerBuffer = StreamPeerBuffer.new()
				s.data_array = df.get_data(tile_layer_data)
				if tile_layer_image >= 0:
					tile_layer.load_tiles(s, df.images[tile_layer_image])
				else:
					tile_layer.load_tiles(s, empty_texture)
				add_child(tile_layer)
				
			elif tile_layer_flags == TileLayerDefault.GAME:
				var game: TileLayerDefault = TileLayerDefault.new()
				game.name = "Game"
				game.width = tile_layer_width
				game.height = tile_layer_height
				game.modulate = Color(1.0, 1.0, 1.0, 0.7)
				game.load_tiles( df.get_stream_data(tile_layer_data), load("res://default/images/DDNet.png") )
				add_child(game)
				
				
			elif  tile_layer_flags == TileLayerDefault.SPEEDUP:
				pass
			elif tile_layer_flags == TileLayerDefault.SWITCH:
				pass
			elif tile_layer_flags == TileLayerDefault.TELE:
				pass
			elif tile_layer_flags == TileLayerDefault.TILES:
				pass
			else:
				print("UNKNOWN LAYER FLAG: ", tile_layer_flags)

			
			
		elif layer_type == LAYER_TYPE_QUADS:
			print("QUAD LAYER: ", name)
			var quad_layer = QuadLayer.new()
			
			
			var versi = layer_info.get_u32()
			var quad_count = layer_info.get_u32()
			var quad_data = layer_info.get_u32()
			var image_id = layer_info.get_32()
			if image_id >= 0:
				pass #TODO: load certain image
			
			if version >= 2:
				var _name = DDString.unpack(PackedByteArray(
					layer_info.get_data(12)[1]))
				if not _name:
					quad_layer.name = " "
					
				else:
					quad_layer.name = _name
				print(">> ", _name)
				
			
			
			var s: StreamPeerBuffer = StreamPeerBuffer.new()
			s.data_array = df.get_data(quad_data)
			var texture: Texture2D = null
			if image_id >= 0:
				texture = df.images[image_id]
				#quad_layer.name = texture.get_meta("image_name")
			quad_layer.load_quads(s, quad_count, texture)
			
			add_child(quad_layer)
					
		else:
			print("skip unknown type")
			
