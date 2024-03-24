extends Object
class_name Bencode

const INT_CHAR = 0x69 # i
const LIST_CHAR = 0x6c # l
const DICT_CHAR = 0x64 # d
const END_CHAR = 0x65 # e
const MINUS = 0x2d
const COLON = 0x3a

static func encode_int(n: int):
	return ('i%de' % n).to_ascii_buffer()

static func encode_string(s):
	var out = ('%d:' % len(s)).to_ascii_buffer()
	if s is String:
		out.append_array(s.to_utf8_buffer())
	else:
		out.append_array(s)
	return out

static func encode_array(a: Array):
	var out = 'l'.to_ascii_buffer()
	for v in a:
		out.append_array(encode(v))
	out.append(END_CHAR)
	return out

static func encode_dict(d: Dictionary):
	var out = 'd'.to_ascii_buffer()
	var sorted_keys = d.keys()
	sorted_keys.sort()
	var pairs = sorted_keys.map(func(k): return [k, d[k]])
	for p in pairs:
		out.append_array(encode(p[0]))
		out.append_array(encode(p[1]))
	out.append(END_CHAR)
	return out

static func encode(v: Variant) -> PackedByteArray:
	if v is Dictionary:
		return encode_dict(v)
	elif v is Array:
		return encode_array(v)
	elif v is int:
		return encode_int(v)
	elif v is String or v is PackedByteArray:
		return encode_string(v)
	return PackedByteArray()

const BE_ERR_END = 'End of buffer reached, expected more data'
const BE_ERR_START = 'Invalid type start: %d'
const BE_ERR_INT = 'Invalid integer character'

static func decode_bare_int(d, pos, end=END_CHAR, allow_negative=true):
	var s = PackedByteArray()
	var idx = pos
	if idx >= d.size():
		return [null, pos, BE_ERR_END]
	while d[idx] != end:
		if idx >= d.size():
			return [null, pos, BE_ERR_END]
		if not ((0x30 <= d[idx] and d[idx] <= 0x39)
				or (allow_negative and d[idx] == MINUS and idx == pos)):
			return [null, pos, BE_ERR_INT]
		s.append(d[idx])
		idx += 1
	idx += 1 # skip end
	return [int(s.get_string_from_ascii()), idx]

static func decode_int(d, pos):
	return decode_bare_int(d, pos + 1)

static func between(a, x, b) -> bool:
	return a <= x and x <= b

static func is_valid_utf8_char(b: PackedByteArray, pos: int=0) -> int:
	var hi_set = 0
	var first = b[pos]
	while first >> 7:
		hi_set += 1
		first >>= 1
	if hi_set == 1:
		return -1
	var count = hi_set + (0 if hi_set else 1)
	var end = pos + count
	if end > b.size():
		return -1
	for c in b.slice(pos + 1, end):
		if c >> 6 != 2: # 0b10
			return -1
	return count

static func is_valid_utf8(b: PackedByteArray) -> bool:
	var idx = 0
	while idx < b.size():
		var inc = is_valid_utf8_char(b, idx)
		if inc == -1:
			return false
		idx += inc
	return true

static func decode_string(d, pos):
	var lenpos = decode_bare_int(d, pos, COLON, false)
	var length = lenpos[0]
	if length == null:
		return lenpos
	var start = lenpos[1]
	var end = start + length
	if end >= d.size():
		return [null, pos, BE_ERR_END]
	var chars = d.slice(start, end)
	if is_valid_utf8(chars):
		return [chars.get_string_from_utf8(), end]
	return [chars, end]

static func decode_array(d, pos):
	var idx = pos + 1
	var o = []
	while d[idx] != END_CHAR:
		var ipos = decode_pos(d, idx)
		if ipos[0] == null:
			return ipos
		o.push_back(ipos[0])
		idx = ipos[1]
		if idx >= d.size():
			return [null, pos, BE_ERR_END]
	return [o, idx + 1]

static func decode_keyvalue(d, pos):
	var idx = pos
	var keypos = decode_pos(d, idx)
	if keypos[0] == null:
		return keypos
	var key = keypos[0]
	idx = keypos[1]
	if idx >= d.size():
		return [null, pos, BE_ERR_END]
	var valpos = decode_pos(d, idx)
	if valpos[0] == null:
		return valpos
	var val = valpos[0]
	idx = valpos[1]
	if idx >= d.size():
		return [null, pos, BE_ERR_END]
	return [[key, val], idx]

static func decode_dict(d, pos):
	var idx = pos + 1
	if idx >= d.size():
		return [null, pos, BE_ERR_END]
	var o = {}
	while d[idx] != END_CHAR:
		var keyval = decode_keyvalue(d, idx)
		if not keyval[0]:
			return keyval
		idx = keyval[1]
		o[keyval[0][0]] = keyval[0][1]
	return [o, idx + 1]

static func decode_pos(d: PackedByteArray, pos: int):
	var c = d[pos]
	if c == DICT_CHAR:
		return decode_dict(d, pos)
	elif c == LIST_CHAR:
		return decode_array(d, pos)
	elif c == INT_CHAR:
		return decode_int(d, pos)
	elif 0x30 <= c and c <= 0x39:
		return decode_string(d, pos)
	return [null, pos, BE_ERR_START % c]

static func decode(d: PackedByteArray) -> Variant:
	var ret = decode_pos(d, 0)
	if ret[0] == null:
		return [ERR_INVALID_DATA, ret[2]]
	return [OK, ret[0]]

# this returns either the info dict encoded exactly as it is in the file,
# or null if it cannot be retrieved
# this is robust against misformatted torrent files
static func get_info(d: PackedByteArray):
	if not d.is_empty() and d[0] == DICT_CHAR:
		var pos = 1
		while pos < d.size() and d[pos] != END_CHAR:
			# while this seems wasteful, we need the end position (of the dict)
			# we need it whether we use this element or not, the end is needed
			var keyval = decode_keyvalue(d, pos)
			if keyval[0] == null:
				return null
			if keyval[0][0] == 'info':
				var key = decode_string(d, pos)
				pos = key[1]
				# keyval[1] is the end of the dictionary
				return d.slice(pos, keyval[1])
			pos = keyval[1]
	return null

static func treekeys(d):
	if not d is Dictionary:
		if d is Array:
			return '[array]'
		elif d is PackedByteArray:
			return '[bytes]'
		elif d is String:
			return '[string]'
		elif d is int:
			return '[int]'
	var out = {}
	for k in d:
		var ok = k
		if ok is PackedByteArray:
			ok = ok.hex_encode()
		out[ok] = treekeys(d[k])
	return out
