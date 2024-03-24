extends Object
class_name Base32

const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'

class BitStream:
	var data
	var position
	var length

	func _init(_data: PackedByteArray=PackedByteArray()):
		data = _data
		position = 0
		length = data.size() * 8

	func read(count: int, pad: bool=true):
		var n = 0
		for i in range(count):
			var byte = floori(position / 8)
			var bit = position % 8
			var selected = 0
			if position < length:
				selected = (data[byte] >> (7 - bit)) & 1
			elif not pad:
				return null
			n <<= 1
			n |= selected
			position += 1
		return n

	func write(n: int, count: int):
		for i in range(count):
			var byte = floori(position / 8)
			var bit = position % 8
			var mask = 0xFF ^ (1 << (7 - bit))
			var selected = ((n >> (count - i - 1)) & 1) << (7 - bit)
			if byte + 1 > len(data):
				data.push_back(0)
			data[byte] &= mask
			data[byte] |= selected
			position += 1
			length = max(position, length)

static func encode(data: PackedByteArray) -> String:
	var out = ''
	var reader = BitStream.new(data)
	while reader.position < reader.length:
		out += alphabet[reader.read(5)]
	return out

static func decode(data: String) -> PackedByteArray:
	var writer = BitStream.new()
	for c in data:
		writer.write(alphabet.find(c), 5)
	return writer.data
