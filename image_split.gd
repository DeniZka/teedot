extends Node2D
const DEFAULT_TILE_COUNT_XY = 16
const COLOR_ITEM_COUNT = 4
const TILE_WIDTH = 16
const TILE_COLORS_LINE = TILE_WIDTH * COLOR_ITEM_COUNT
const TILE_HEIGHT = 16
var map_size: Vector2i
var atlas_size := Vector2i(16, 16)
var atlas_width = TILE_WIDTH * atlas_size.x
var atlas_height = TILE_HEIGHT * atlas_size.y
var data_width: int
var data_height: int
var data: PackedByteArray
var atlac_crc_range = -1
var atlas_crc := PackedInt32Array()
var atlas_escapes := PackedByteArray()
var atlas_data := PackedByteArray()

var crc_table = [0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F,
	0xE963A535, 0x9E6495A3, 0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988,
	0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91, 0x1DB71064, 0x6AB020F2,
	0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
	0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9,
	0xFA0F3D63, 0x8D080DF5, 0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172,
	0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B, 0x35B5A8FA, 0x42B2986C,
	0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
	0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423,
	0xCFBA9599, 0xB8BDA50F, 0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924,
	0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D, 0x76DC4190, 0x01DB7106,
	0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
	0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB, 0x086D3D2D,
	0x91646C97, 0xE6635C01, 0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E,
	0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457, 0x65B0D9C6, 0x12B7E950,
	0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
	0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7,
	0xA4D1C46D, 0xD3D6F4FB, 0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0,
	0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9, 0x5005713C, 0x270241AA,
	0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
	0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81,
	0xB7BD5C3B, 0xC0BA6CAD, 0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A,
	0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683, 0xE3630B12, 0x94643B84,
	0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
	0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB,
	0x196C3671, 0x6E6B06E7, 0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC,
	0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5, 0xD6D6A3E8, 0xA1D1937E,
	0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
	0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55,
	0x316E8EEF, 0x4669BE79, 0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236,
	0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F, 0xC5BA3BBE, 0xB2BD0B28,
	0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
	0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A, 0x9C0906A9, 0xEB0E363F,
	0x72076785, 0x05005713, 0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38,
	0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21, 0x86D3D2D4, 0xF1D4E242,
	0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
	0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69,
	0x616BFFD3, 0x166CCF45, 0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2,
	0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB, 0xAED16A4A, 0xD9D65ADC,
	0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
	0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605, 0xCDD70693,
	0x54DE5729, 0x23D967BF, 0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94,
	0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D];

func fCRC32(bytes: PackedByteArray, count: int = -1) -> int:
	var crc = 0 ^ (-1)
	var bytes_range = bytes.size()
	if count != -1:
		bytes_range = count
	for i in range(bytes_range):
		crc = ((crc >> 8) & 0x00FFFFFF) ^ crc_table[(crc ^ bytes[i]) & 0xFF]
	crc = crc ^ (-1)
	# Signed to unsigned
	if (crc < 0):
		crc += 4294967296;
	return crc

func get_atlas_crcs(count: int = -1) -> PackedInt32Array:
	var crcs := PackedInt32Array()
	for i in range(map_size.y):
		for j in range(map_size.x):
			crcs.append( fCRC32( get_tile_data_v(Vector2i(j,i)), count ) )
	return crcs
	
func check_unique(crcs: PackedInt32Array) -> bool:
	var cut: PackedInt32Array = crcs.duplicate()
	#remove escapes copy
	for i in range(atlas_escapes.size() - 1, -1, -1):
		if atlas_escapes[i]:
			cut.remove_at(i)
		
	for i in range(cut.size() - 1):
		if cut.find(cut[i], i + 1) >= 0:
			return false
	return true

func optimize_atlas_crc_range():
	atlas_crc = get_atlas_crcs()
	
	atlas_escapes.resize(atlas_crc.size())
	atlas_escapes.fill(0)
	
	#escape empty items (same items)
	for i in range(atlas_crc.size() - 1):
		if atlas_escapes[i]: #skip if self is escape (marked as not unique)
			continue
		var f_res = 0
		var j = i + 1 #next
		while f_res != -1 and j < atlas_crc.size():
			f_res = atlas_crc.find(atlas_crc[i], j)
			if f_res >= 0:
				atlas_escapes[f_res] = 1
				j = f_res + 1

	#get shortest unique CRC with halving method
	#var prev_mid_point = TILE_WIDTH * TILE_HEIGHT * 3
	#var mid_point = prev_mid_point / 2
	#while check_unique( get_atlas_crcs(mid_point) ):
	#	prev_mid_point = mid_point
	#	mid_point = mid_point / 2

func get_tile_data_v(v: Vector2i) -> PackedByteArray:
	var from = 0 
	var tile_data: PackedByteArray = []
	var full_data_width = data_width * COLOR_ITEM_COUNT
	var yx_shift = v.y * TILE_HEIGHT * full_data_width + v.x * TILE_COLORS_LINE
	for i in range(TILE_HEIGHT):
		from = yx_shift + i * full_data_width
		tile_data.append_array(data.slice(from, from + TILE_COLORS_LINE))
	return tile_data
	
func put_atlas_tile_v(v: Vector2i, tile_data: PackedByteArray):
	var from = 0 
	var full_data_width = atlas_width * COLOR_ITEM_COUNT
	var yx_shift = v.y * TILE_HEIGHT * full_data_width + v.x * TILE_COLORS_LINE
	for i in range(TILE_HEIGHT):
		from = yx_shift + i * full_data_width
		var slic := tile_data.slice(i * TILE_COLORS_LINE, i * TILE_COLORS_LINE + TILE_COLORS_LINE)
		for j in range(0, TILE_COLORS_LINE): #(i*TILE_HEIGHT, i*TILE_HEIGHT + TILE_COLORS_LINE)
			atlas_data.set(from + j, slic[j])
	
func get_tile_data(index: int) -> PackedByteArray:
	return get_tile_data_v( Vector2i(index % map_size.x, index / map_size.x) )
	
func put_atlas_tile(index: int, tile_data: PackedByteArray):
	put_atlas_tile_v( Vector2i(index % atlas_size.x, index / atlas_size.x), tile_data )
	
func get_atlas_data_v(v: Vector2i) -> PackedByteArray:
	return PackedByteArray()
	
func get_atlas_image() -> Image:
	return Image.create_from_data(256, 256, false, Image.FORMAT_RGBA8, atlas_data)

func get_tile_image_v(v: Vector2i) -> Image:
	var tile_data := get_tile_data_v(v)
	var im = Image.new()
	im.set_data(TILE_WIDTH, TILE_HEIGHT, false, Image.FORMAT_RGBA8, tile_data)
	return im
	
func get_tile_image(index: int) -> Image:
	return get_tile_image_v( Vector2i(index % map_size.x, index / map_size.x) )

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MapFile.new("res://Tutorial.map_") #DyrteeZ.map_")
	
	var file_name = "DuckTalesMap1BG"
	var map_file_path = "res://" + file_name + ".png"
	var atlas_file_path = "res://" + file_name + "_atlas.png"
	#temp atlas with saving
	atlas_crc.resize(16*16)
	atlas_crc.fill(0)
	atlas_data.resize(TILE_WIDTH * 16 * TILE_WIDTH * 16 * 4)
	atlas_data.fill(0)
	var a_im = get_atlas_image()
	#a_im.save_png(atlas_file_path)
	
	
	
	var tl := TileMapLayer.new()
	tl.name = file_name
	tl.tile_set = TileSet.new()
	tl.tile_set.tile_size = Vector2i(16, 16)

	
	
	var texture := ImageTexture.create_from_image(a_im)
	var source := TileSetAtlasSource.new()
	source.texture_region_size = Vector2i(16, 16)
	source.texture = texture
	for y in range(DEFAULT_TILE_COUNT_XY):
		for x in range(DEFAULT_TILE_COUNT_XY):
			source.create_tile(Vector2i(x, y))
	tl.tile_set.add_source(source)
	
	#
	var dt := Image.load_from_file(map_file_path)
	data = dt.data["data"]
	data_width = dt.data["width"]
	data_height = dt.data["height"]
	map_size = Vector2i(data_width / TILE_WIDTH, data_height / TILE_HEIGHT)
	var atlas_start_index = 1
	for i in range(map_size.x * map_size.y):
		var t_data = get_tile_data(i)
		var t_crc = fCRC32(t_data)
		
		var t_atlas_idx = atlas_crc.find(t_crc)
		if t_atlas_idx == -1:
			put_atlas_tile(atlas_start_index, t_data)
			atlas_crc[atlas_start_index] = t_crc
			tl.set_cell( Vector2i(i % map_size.x, i / map_size.x), 0, Vector2i(atlas_start_index % 16, atlas_start_index / 16) )
			atlas_start_index += 1
		else:
			tl.set_cell( Vector2i(i % map_size.x, i / map_size.x), 0, Vector2i(t_atlas_idx % 16, t_atlas_idx / 16) )
		
	a_im = get_atlas_image()
	a_im.save_png(atlas_file_path)
	#tl.get_im
	
	var packed_scene = PackedScene.new()
	packed_scene.pack(tl)
	ResourceSaver.save(packed_scene, "res://" + tl.name + ".tscn")
	
