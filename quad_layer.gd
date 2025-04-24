@icon("res://default/quad.svg")
class_name QuadLayer
extends Node2D

@export var version: int
@export var count: int
@export var data: int
@export var image: int

const DIV = 512
const DIV2 = DIV * 2

var t_quad = load("res://default/quad.tscn")

func load_quads(s: StreamPeerBuffer, count: int, texture: Texture2D):
	for i in range(count):
		print("count", count)
		var quad: QuadItem = QuadItem.new()
		quad.name = "Quad_" + str(i)
		var tex_size = Vector2(1.0, 1.0)
		var div2 = Vector2(DIV2, DIV2)
		if texture:
			#quad.name = texture.get_meta("image_name")
			tex_size = texture.get_size()
			div2 = Vector2(tex_size.x / DIV2, tex_size.y / DIV2)
			quad.texture = texture
		
		quad.polygon = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])#, Vector2.ZERO])
		quad.polygon[1] = Vector2( s.get_32(), s.get_32()) / DIV 
		quad.polygon[0] = Vector2( s.get_32(), s.get_32()) / DIV
		quad.polygon[2] = Vector2( s.get_32(), s.get_32()) / DIV
		quad.polygon[3] = Vector2( s.get_32(), s.get_32()) / DIV
		
		#aquad.polygon[4] = 
		Vector2( s.get_32(), s.get_32()) / DIV #midpoint
		quad.vertex_colors = PackedColorArray([Color(0), Color(0), Color(0), Color(0)])
		quad.vertex_colors[1] = Color( s.get_32()/255.0, s.get_32()/255.0, s.get_32()/255.0, s.get_32()/255.0) 
		quad.vertex_colors[0] = Color( s.get_32()/255.0, s.get_32()/255.0, s.get_32()/255.0, s.get_32()/255.0) 
		quad.vertex_colors[2] = Color( s.get_32()/255.0, s.get_32()/255.0, s.get_32()/255.0, s.get_32()/255.0) 
		quad.vertex_colors[3] = Color( s.get_32()/255.0, s.get_32()/255.0, s.get_32()/255.0, s.get_32()/255.0) 
		
		
		quad.uv = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
		quad.uv[1] = Vector2(s.get_u32(), s.get_u32()) * div2
		quad.uv[0] = Vector2(s.get_u32(), s.get_u32()) * div2
		quad.uv[2] = Vector2(s.get_u32(), s.get_u32()) * div2
		quad.uv[3] = Vector2(s.get_u32(), s.get_u32()) * div2
		
		quad.polygons = [[0,1,3], [1,2,3]]
		quad.pos_env = s.get_32()
		quad.pos_env_offset = s.get_32()
		quad.color_env = s.get_32()
		quad.color_env_offset = s.get_32()
 	
		add_child(quad)
	
