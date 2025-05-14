extends RefCounted
class_name MapFile

enum {
  TYPE_VERSION = 0,
  TYPE_INFO = 1,
  TYPE_IMAGE = 2,
  TYPE_ENVELOPE = 3,
  TYPE_GROUP = 4,
  TYPE_LAYER = 5,
  TYPE_ENVPOINTS = 6,
  TYPE_SOUNDS = 7,
  TYPE_UUID = 0xffff
}

const TYPE = "type"
const START = "start"
const NUM = "num"
const OFFSET = "offset"
const SIZE = "size"
const COMP_SIZE = "comp_size"
const ID = "id"
const DATA = "data"

const INFO_VERISON = "version"
const INFO_AUTHOR = "author"
const INFO_MAP_VERSION = "map_version"
const INFO_CREDITS = "credits"
const INFO_LICENSE = "license"
const INFO_SETTING = "setting"

const IMAGE_VERSION = "version"
const IMAGE_WIDTH = "width"
const IMAGE_HEIGHT = "height"
const IMAGE_EXTERNAL = "external"
const IMAGE_NAME = "name"
const IMAGE_DATA = "data"
const IMAGE_VARIANT_V2 = "variant"

const ENV_VERSION = "version"
const ENV_CHANNEL = "channel"
const ENV_START_POTIN = "start"
const ENV_NUM_POINTS = "num"
const ENV_NAME = "name"
const ENV_SYNC_V2 = "sync"

const GROUP_VERSION = "verion"
const GROUP_X_OFFSET = "x_offset"
const GROUP_Y_OFFSET = "y_offset"
const GROUP_X_PARALLAX = "x_parallax"
const GROUP_Y_PARALLAX = "y_parallax"
const GROUP_START_LAYER = "start"
const GROUP_NUM_LAYERS = "num"
const GROUP_CLIPPING_V2 = "clipping"
const GROUP_CLIP_X_V2 = "clip_x"
const GROUP_CLIP_Y_V2 = "clip_y"
const GROUP_CLIP_WIDTH_V2 = "clip_wdith"
const GROUP_CLIP_HEIGHT_V2 = "clip_height"
const GROUP_NAME_V3 = "name"

const LAYER_VERSION = "layer_version"
const LAYER_TYPE = "layer_type"
const LAYER_FLAGS = "layer_flags"
const LAYER_TYPE_TILEMAP = 2
const LAYER_TYPE_QUADS = 3
const LAYER_TYPE_DEPR_SOUND = 9
const LAYER_TYPE_SOUNDS = 10
const LAYER_QUADS_VERSION = "version"
const LAYER_QUADS_NUM = "num"
const LAYER_QUADS_DATA = "data"
const LAYER_QUADS_NAME = ""

var map_node: MapNode = null
	
var data: PackedByteArray = []
var version: int = 0
var size: int = 0
var swap_len: int = 0
var num_item_types: int = 0
var num_items: int = 0
var num_raw_data: int = 0
var item_size: int = 0
var data_size: int = 0
var item_types_start: int = 0
var item_offset_start: int = 0
var data_offset_start: int = 0
var data_size_start: int = 0
var item_start: int = 0
var data_start: int = 0

var item_types = {}
var items_raw : Array[StreamPeerBuffer]
var datas_raw : Array[PackedByteArray]
var items : Dictionary

var itemOffsets = []
var dataOffsets = []

var dataInfos = []

var decData = {}
var images = {}

func unpack_version(buf: StreamPeerBuffer):
	return buf.get_32()
	
func pack_version(version: int):
	var stream := StreamPeerBuffer.new()
	stream.put_32(version)
	return stream
	
func unpack_info(buf: StreamPeerBuffer):
	return {
		INFO_VERISON: buf.get_32(),
		INFO_AUTHOR: buf.get_32(),
		INFO_MAP_VERSION: buf.get_32(),
		INFO_CREDITS: buf.get_32(),
		INFO_LICENSE: buf.get_32(),
		INFO_SETTING: buf.get_32()
	}
	
func unpack_image(buf: StreamPeerBuffer):
	var version = buf.get_32()
	var width = buf.get_32()
	var height = buf.get_32()
	var external = buf.get_32()
	var image_name = DDString.unpack( PackedByteArray(buf.get_data(8*4)[1]) )
	var image_data_idx =  buf.get_32()
	if version >= 2: #only vanila
		var variant_ = buf.get_32()
	var it : Texture2D
	if external:
		it = load("res://default/external/" + image_name + ".png")
	else:
		var fn: String = "res://images/internal/" + image_name + ".png"
		if not FileAccess.file_exists(fn):
			var image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, datas_raw[image_data_idx])
			image.save_png(fn)
			it = ImageTexture.create_from_image(image)
			it.set_meta("image_name", image_name)
			images.push_back(it)
		else:
			it = load(fn)
			images.push_back( it )
	it.set_meta("image_name", image_name)
	return it
	
func unpack_envilope(buf: StreamPeerBuffer):
	var inf = {
		ENV_VERSION: buf.get_32(),
		ENV_CHANNEL: buf.get_32(),
		ENV_START_POTIN: buf.get_32(),
		ENV_NUM_POINTS: buf.get_32(),
		ENV_NAME: DDString.unpack( PackedByteArray(buf.get_data(8*4)[1]) ),
		ENV_SYNC_V2: 0
	}
	if inf[ENV_VERSION] >= 2:
		inf[ENV_SYNC_V2] = buf.get_32()
	
func unpack_group(buf: StreamPeerBuffer):
	var group_layer = GroupLayer.new()
	var version = buf.get_32()
	group_layer.position = -2.0 * Vector2( buf.get_32(), buf.get_32() )
	group_layer.parallax = Vector2i(buf.get_32(), buf.get_32())
	group_layer.read_layer_index = buf.get_32()
	group_layer.read_layer_count = buf.get_32()
	if version >= 2:
		group_layer.clipping = bool(buf.get_32())
		group_layer.clip = Rect2(buf.get_32(), buf.get_32(), buf.get_32(), buf.get_32())
	if version >= 3:
		var _name = DDString.unpack( PackedByteArray(buf.get_data(3*4)[1]) )
		if not _name:
			group_layer.name = " "
		else:
			group_layer.name = _name

func unpack_layer(layer_info: StreamPeerBuffer):
	var varsion = layer_info.get_u32()
	var layer_type = layer_info.get_u32()
	var flags = layer_info.get_u32()
	if layer_type == LAYER_TYPE_TILEMAP:
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
			
			var s: StreamPeerBuffer = StreamPeerBuffer.new()
			s.data_array = df.get_data(tile_layer_data)
			if tile_layer_image >= 0:
				tile_layer.load_tiles(s, tile_layer_width, tile_layer_height, df.images[tile_layer_image])
			else:
				tile_layer.load_tiles(s, tile_layer_width, tile_layer_height, empty_texture)
			add_child(tile_layer)
			
		elif tile_layer_flags == TileLayerDefault.GAME:
			var game: TileLayerDefault = TileLayerDefault.new()
			game.name = "Game"
			game.modulate = Color(1.0, 1.0, 1.0, 0.7)
			game.load_tiles( df.get_stream_data(tile_layer_data), tile_layer_width, tile_layer_height, load("res://default/images/DDNet.png") )
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
		
	pass


func _init(file_name: String) -> void:
	var fa: FileAccess = FileAccess.open(file_name, FileAccess.READ)
	print("Header: ", fa.get_buffer(4))
	version = fa.get_32()
	print("Version: ", version)
	if version != 4:
		print("invalid map version")
		return
	size = fa.get_32()
	swap_len = fa.get_32()
	num_item_types = fa.get_32()
	num_items = fa.get_32()
	num_raw_data = fa.get_32()
	item_size = fa.get_32()
	data_size = fa.get_32()
	item_types_start = fa.get_position()
	item_offset_start = item_types_start + num_item_types * 12
	data_offset_start = item_offset_start + num_items * 4
	data_size_start = data_offset_start + num_raw_data * 4
	item_start = data_size_start + num_raw_data * 4
	data_start = item_start + item_size
	
	#item types
	for i in range(0, num_item_types):
		print("There are ", i, " item types")
		var type = fa.get_32()
		var start = fa.get_32()
		var num = fa.get_32()
		item_types[type] = {
			START: start,
			NUM: num
		}
		items[type] = {}
		#items[type].resize(num)
		
	#item offsets
	for i in range(0, num_items):
		itemOffsets.push_back(fa.get_32())
	# offsets
	for i in range(0, num_raw_data):
		dataOffsets.push_back(fa.get_32())
	
	map_node = MapNode.new()
	
	#get_items from item_start
	var buf := PackedByteArray()
	buf = fa.get_buffer(item_size)
	for i in range(num_items):
		var ibuf := StreamPeerBuffer.new()
		if i < num_items - 1:
			ibuf.data_array = buf.slice(itemOffsets[i], itemOffsets[i+1])
		else:
			ibuf.data_array = buf.slice(itemOffsets[i])
		items_raw.append(ibuf)
		
		
	buf = fa.get_buffer(data_size)
	for i in range(num_raw_data):
		#var dbuf := StreamPeerBuffer.new()
		if i < num_items - 1:
			datas_raw.append( buf.slice(itemOffsets[i], itemOffsets[i+1]) )
		else:
			datas_raw.append( buf.slice(itemOffsets[i]) )
	#print(fa.get_position())
	
	#parse items
	for i in range(len(items_raw)):
		items_raw[i].seek(0)
		var idx = items_raw[i].get_u16()
		var typ = items_raw[i].get_u16()
		var siz = items_raw[i].get_u32()
		var item_data = StreamPeerBuffer.new()
		item_data.data_array = items_raw[i].get_data(siz)[1]
		
		var inf = ""
		if typ == TYPE_VERSION:
			items[typ][idx] = unpack_version(item_data)
		if typ == TYPE_INFO:
			items[typ][idx] = unpack_info(item_data)
		if typ == TYPE_IMAGE:
			items[typ][idx] = unpack_image(item_data)
		if typ == TYPE_ENVELOPE:
			items[typ][idx] = unpack_envilope(item_data)
			
		if typ == TYPE_GROUP:
			items[typ][idx] = unpack_group(item_data)
		if typ == TYPE_LAYER:
			items[typ][idx] = unpack_layer(item_data)
			#inf = {
				#LAYER_VERSION: item_data.get_32(),
				#LAYER_TYPE: item_data.get_32(),
				#LAYER_FLAGS: item_data.get_32(),
			#}
			#if inf[LAYER_TYPE] == LAYER_TYPE_QUADS:
				#inf[LAYER_QUADS_VERSION] = item_data.get_32()
				#inf[LAYER_QUADS_NUM] = item_data.get_32()
				#inf[LAYER_QUADS_DATA] = item_data.get_32()
				#inf[LAYER_QUADS_NAME] = ""
				#if inf[LAYER_QUADS_VERSION] >= 2:
					#inf[LAYER_QUADS_NAME] = DDString.unpack( PackedByteArray(item_data.get_data(3*4)[1]) )
					
					
			#if inf[LAYER_TYPE] == LAYER_TYPE_TILEMAP:
				#inf[VERSION] = item_data.get_32()
				#inf[WIDTH] = item_data.get_32()
				#inf[HEIGHT] = item_data.get_32()
				#inf[FLAGS] = item_data.get_32()
				#inf[COLOR] = Color(item_data.get_u32() / 255.0, item_data.get_u32() / 255.0, item_data.get_u32() / 255.0, item_data.get_u32() / 255.0)
				#inf[COLOR_ENV] = item_data.get_32()
	#[1] opt *color_envelope
	#[1] color_envelope_offset
	#[1] opt *image
	#[1] &data: 2d-array of the the tile type 'Tile'
			#print(item_data.data_array)
		
		
		#if typ > TYPE_SOUNDS:
		#	print(item_data.data_array)
		
		#TODO: create item by type
		#sbuf.clear()
		
	print(fa.get_position())
	
	

	
		
	# decompress data
	data = FileAccess.get_file_as_bytes(file_name)
	#for i in range(0, num_raw_data):
	#	var start_offset = dataInfos[i][OFFSET] + data_start
	#	var comp_part = data.slice(
	#		start_offset,
	#		start_offset + dataInfos[i][COMP_SIZE] 
	#		)
	#	decData.push_back(
	#		comp_part.decompress(dataInfos[i][SIZE], FileAccess.COMPRESSION_DEFLATE)
	#		)
	#images
	var images_info = item_types[TYPE_IMAGE] #get_type(TYPE_IMAGE)
	if not images_info.is_empty():
		for i in range(0, images_info[MapFile.NUM]):
			var image_item = get_item(images_info[MapFile.START] + i)
			var image_info: PackedByteArray = image_item[MapFile.DATA]
			var version = image_info.decode_u32(0)
			var width = image_info.decode_u32(4)
			var height = image_info.decode_u32(8)
			var external = bool(image_info.decode_u32(12))
			var name = image_info.decode_s32(16)
			var data = image_info.decode_s32(20)
			var image: Image = null
			
			var image_name = get_data(name).get_string_from_ascii()
			
			

func get_data(index: int) -> PackedByteArray:
	#find in cache
	if index in decData:
		return decData[index]
	#decompress on demand
	var start_offset = dataInfos[index][OFFSET] + data_start
	var comp_part = data.slice(
		start_offset,
		start_offset + dataInfos[index][COMP_SIZE] 
		)
	#cache
	decData[index] = comp_part.decompress(dataInfos[index][SIZE], FileAccess.COMPRESSION_DEFLATE)
	return decData[index]
	
func get_stream_data(index: int) -> StreamPeerBuffer:
	#find in cache
	var stream = StreamPeerBuffer.new()
	
	if index in decData:
		stream.data_array = decData[index]
		return decData[index]
	#decompress on demand
	var start_offset = dataInfos[index][OFFSET] + data_start
	var comp_part = data.slice(
		start_offset,
		start_offset + dataInfos[index][COMP_SIZE] 
		)
	#cache
	decData[index] = comp_part.decompress(dataInfos[index][SIZE], FileAccess.COMPRESSION_DEFLATE)
	stream.data_array = decData[index]
	return stream
	
func get_item_size(index: int):
	if index == num_items - 1:
		return item_size - itemOffsets[index]
	return itemOffsets[index + 1] - itemOffsets[index]

func get_item(index: int) -> Dictionary:
	var offset = item_start + itemOffsets[index]
	var item_size = get_item_size(index)
	return {
		ID: data.decode_u16(offset),
		TYPE: data.decode_s16(offset + 2),
		SIZE: data.decode_u32(offset + 4),
		DATA: data.slice(offset + 8, offset + 8 + item_size)
	}
	
#func get_type(type: int) -> Dictionary:
	#for i in range(num_item_types):
		#if itemTypes[i][TYPE] == type:
			#return itemTypes[i]
	#return {}

func find_uuid_type(uuid: PackedByteArray) -> Dictionary:
	var uuid_index = item_types[TYPE_UUID] #get_type(0xffff)
	if not uuid_index:
		return {}
	for i in range(uuid_index[NUM]):
		var item = get_item(uuid_index[START] + i)
		var view: PackedByteArray = item[DATA].slice() #FIXME: check UUIDS
		view.encode_u32(0, view.decode_u32(0))
		view.encode_u32(4, view.decode_u32(4))
		view.encode_u32(8, view.decode_u32(8))
		view.encode_u32(12, view.decode_u32(12))
		if view == uuid:
			return  item_types[item[ID]] #get_type(item[ID])
	return {}
	
func find_item(type: int, id: int) -> Dictionary:
	if not type in item_types:
		return {}
	var t = item_types[type]  #get_type(type)
	#if not t:
	#	return {}
	
	for i in range(t[NUM]):
		var item = get_item(t[START] + i)
		if item[ID] == id:
			return item
	return {}
	
