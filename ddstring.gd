extends Node
class_name DDString

static func unpack(p_name: PackedByteArray) -> String:
	#var s: StreamPeerBuffer = StreamPeerBuffer.new()
	#s.data_array = p_name
	#s.big_endian = true
	#s.get_partial_data(4)
	#print("String in: ", p_name)
	var b = p_name.slice(0, 4)
	b.reverse()
	var t = p_name.slice(4, 8)
	t.reverse()
	b += t
	t = p_name.slice(8, 12)
	t.reverse()
	b += t
	for j in range(0, b.size()):
		if b[j] == 0:
			break
		b[j] = b[j] - 128
	var out = b.get_string_from_ascii()
	#print("String out: ", out)
	return out
	
static func pack(s: String) -> PackedByteArray:
	return []
