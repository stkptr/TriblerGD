extends RefCounted
class_name TorrentList

var list
var hash_lookup

func _init(_list: Array):
	list = _list
	hash_lookup = {}
	for t in range(len(list)):
		hash_lookup[list[t].infohash] = t

static func from_dict_array(a: Array):
	return TorrentList.new(a.map(Torrent.from_dict))

func find_infohash(infohash: String):
	return hash_lookup.get(infohash)

func get_infohash(infohash: String):
	var index = find_infohash(infohash)
	if index != null:
		return list[index]
