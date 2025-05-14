extends TileMapLayer
class_name TileLayerDefault

const DEFAULT_TILE_SIZE = 64
const DEFAULT_TILE_COUNT_XY = 16
const FLIP_V = 0x01
const FLIP_H = 0x02
const ROT = 0x08

enum {TILES=0, GAME=1, TELE=2, SPEEDUP=4, FRONT=8, SWITCH=16}


func load_tiles(s: StreamPeerBuffer, width: int, height: int, texture: Texture2D):
	tile_set = TileSet.new()
	var tile_size = Vector2i(texture.get_width() / DEFAULT_TILE_COUNT_XY, texture.get_height() / DEFAULT_TILE_COUNT_XY)
	scale.x = float(DEFAULT_TILE_SIZE) / tile_size.x
	scale.y = float(DEFAULT_TILE_SIZE) / tile_size.y
	tile_set.tile_size = tile_size
		
	if texture:
		var source = TileSetAtlasSource.new()
		source.texture_region_size = tile_size
		source.texture = texture
		for y in range(DEFAULT_TILE_COUNT_XY):
			for x in range(DEFAULT_TILE_COUNT_XY):
				source.create_tile(Vector2i(x, y))
		tile_set.add_source(source)
	
	var ids =  []
	for i in height: 
		for j in width:
			var id = s.get_u8() #FIXME: width/16
			var dd_flags = s.get_u8()
			var flags: int = 0
			var flip_v = (dd_flags & 0x01) == 0x01 
			var flip_h = (dd_flags & 0x02) == 0x02
			var cw_rot = (dd_flags & 0x08) == 0x08
			#print("idx: ", j, "\tflip_v: ", flip_v, "\tflip_h: ", flip_h, "\trot:", cw_rot)
			if     flip_v && not flip_h && not cw_rot:
				flags += TileSetAtlasSource.TRANSFORM_FLIP_H
			if not flip_v &&     flip_h && not cw_rot:
				flags += TileSetAtlasSource.TRANSFORM_FLIP_V
			if     flip_v &&     flip_h && not cw_rot:
				flags += TileSetAtlasSource.TRANSFORM_FLIP_H
				flags += TileSetAtlasSource.TRANSFORM_FLIP_V
			if not flip_v &&     flip_h &&     cw_rot:
				flags += TileSetAtlasSource.TRANSFORM_TRANSPOSE
				
			if not flip_v && not flip_h &&     cw_rot:
				flags += TileSetAtlasSource.TRANSFORM_FLIP_H
				flags += TileSetAtlasSource.TRANSFORM_TRANSPOSE
				
			if flip_v && flip_h && cw_rot:
				flags += TileSetAtlasSource.TRANSFORM_FLIP_V
				flags += TileSetAtlasSource.TRANSFORM_TRANSPOSE
				
			if     flip_v && not flip_h &&     cw_rot:
				flags += TileSetAtlasSource.TRANSFORM_TRANSPOSE
				flags += TileSetAtlasSource.TRANSFORM_FLIP_H
				flags += TileSetAtlasSource.TRANSFORM_FLIP_V
				
			s.get_u16()
			if id != 0:
				ids.push_back(id)
				set_cell(Vector2i(j, i), 0, Vector2i( id % 16, int(id/16)), flags)
				
				
func save_tiles():
	var buf := StreamPeerBuffer.new()
	var rect := get_used_rect()
	#FIXME: start only form 0:0 Godot
	for i in range(rect.size.y + rect.position.y):
		for j in range(rect.size.x + rect.position.x):
			var tile_info := get_cell_tile_data(Vector2i(j,i))
			buf.put_u8( tile_info.texture_origin.y * 16 + tile_info.texture_origin.x )
			if not tile_info.flip_h and not tile_info.flip_v and not tile_info.transpose:
				buf.put_u8(0x0)
			if     tile_info.flip_h and not tile_info.flip_v and not tile_info.transpose:
				buf.put_u8(FLIP_V)
			if not tile_info.flip_h and     tile_info.flip_v and not tile_info.transpose:
				buf.put_u8(FLIP_H)
			if     tile_info.flip_h and     tile_info.flip_v and not tile_info.transpose:
				buf.put_u8(FLIP_V | FLIP_H)
			if not tile_info.flip_h and     tile_info.flip_v and     tile_info.transpose:
				buf.put_u8(ROT)
			if not tile_info.flip_h and not tile_info.flip_v and     tile_info.transpose:
				buf.put_u8(FLIP_H | ROT)
			if     tile_info.flip_h and     tile_info.flip_v and     tile_info.transpose:
				buf.put_u8(FLIP_V | ROT)
			if not tile_info.flip_h and     tile_info.flip_v and     tile_info.transpose:
				buf.put_u8(FLIP_V | FLIP_H | ROT)
			
			buf.put_u16(0x0000) #skip and unused fields
			
			
			
			

func _get_configuration_warnings() -> PackedStringArray:
	if not get_parent() is GroupLayer:
		return ["TileLayer Must be under group"]
	return []
