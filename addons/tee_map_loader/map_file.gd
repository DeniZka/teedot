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
}

const TYPE = "type"
const START = "start"
const NUM = "num"
const OFFSET = "offset"
const SIZE = "size"
const COMP_SIZE = "comp_size"
const ID = "id"
const DATA = "data"

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

var itemTypes = []
var itemOffsets = []

var dataInfos = []

var decData = {}
var images = []

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
		itemTypes.push_back( {
			TYPE: fa.get_32(),
			START: fa.get_32(),
			NUM: fa.get_32()
		} )
		
	#item offsets
	for i in range(0, num_items):
		itemOffsets.push_back(fa.get_32())
		
	# data infos
	# offsets
	for i in range(0, num_raw_data):
		dataInfos.push_back( {
			OFFSET: fa.get_32(),
			SIZE: -1,
			COMP_SIZE: -1
		})
		
	#data sizes
	for i in range(0, num_raw_data):
		#uncompressed size
		dataInfos[i][SIZE] = fa.get_32()
		# compressed size
		if i == num_raw_data - 1:
			dataInfos[i][COMP_SIZE] = data_size - dataInfos[i][OFFSET]
		else:
			dataInfos[i][COMP_SIZE] = dataInfos[i + 1][OFFSET] - dataInfos[i][OFFSET]
		
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
	var images_info = get_type(TYPE_IMAGE)
	for i  in range(0, images_info[MapFile.NUM]):
		
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
		if external:
			print("00000 ", image_name)
			var it = load("res://default/external/" + image_name + ".png")
			images.push_back(it)
		else:
			var fn: String = "res://images/internal/" + image_name + ".png"
			if not FileAccess.file_exists(fn):
				image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, get_data(data))
				image.save_png(fn)
				var it := ImageTexture.create_from_image(image)
				it.set_meta("image_name", image_name)
				images.push_back(it)
			else:
				var it : Texture2D = load(fn)
				it.set_meta("image_name", image_name)
				images.push_back( it )
			

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
	
func get_type(type: int) -> Dictionary:
	for i in range(num_item_types):
		if itemTypes[i][TYPE] == type:
			return itemTypes[i]
	return {}

func find_uuid_type(uuid: PackedByteArray) -> Dictionary:
	var uuid_index = get_type(0xffff)
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
			return  get_type(item[ID])
	return {}
	
func find_item(type: int, id: int) -> Dictionary:
	var t = get_type(type)
	if not t:
		return {}
	
	for i in range(t[NUM]):
		var item = get_item(t[START] + i)
		if item[ID] == id:
			return item
	return {}
	
