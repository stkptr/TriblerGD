extends RefCounted
class_name Torrent

var meta_time

var infohash
var title
var size

var trackers
var download_info

var category
var seed_count
var leech_count

var created_at
var checked_at

# statements

const default_title = 'Unknown name'
const default_category = 'other'

const defaults = {
	'title': default_title,
	'size': 0,
	'trackers': [],
	'category': default_category,
}

static func decode_infohash(ih):
	if ih is PackedByteArray and ih.size() == 20:
		return ih
	var hex = RegEx.create_from_string('^[0-9a-f]{40}$')
	if hex.search(ih):
		return ih.hex_decode()
	var b32 = RegEx.create_from_string('^[A-Z2-7]{32}$')
	if b32.search(ih):
		return Base32.decode(ih)

func _init(_infohash,
		_title: String=default_title,
		_size: int=0,
		_trackers: Array=[],
		_category: String=default_category,
		_seed_count: int=0,
		_leech_count: int=0,
		_created_at: int=0,
		_checked_at: int=0,
		_download_info=null,
		_meta_time=null):
	meta_time = _meta_time
	if meta_time == null:
		meta_time = Time.get_ticks_usec()
	infohash = Torrent.decode_infohash(_infohash).hex_encode()
	title = _title
	size = _size
	trackers = _trackers
	category = _category
	seed_count = _seed_count
	leech_count = _leech_count
	created_at = _created_at
	checked_at = _checked_at
	download_info = _download_info

static func null_default(attribute, val):
	return val if val != defaults.get(attribute) else null

static func pick_newest(a, b, attribute: String):
	var aval = null_default(attribute, a.get(attribute))
	var bval = null_default(attribute, b.get(attribute))
	if aval == null and bval != null:
		return bval
	elif aval != null and bval == null:
		return aval
	# get again as they may be null instead of default
	if a.meta_time > b.meta_time:
		return a.get(attribute)
	return b.get(attribute)

static func merge(a: Torrent, b: Torrent) -> Torrent:
	return Torrent.new(
		pick_newest(a, b, 'infohash'),
		pick_newest(a, b, 'title'),
		pick_newest(a, b, 'size'),
		pick_newest(a, b, 'trackers'),
		pick_newest(a, b, 'category'),
		pick_newest(a, b, 'seed_count'),
		pick_newest(a, b, 'leech_count'),
		pick_newest(a, b, 'created_at'),
		pick_newest(a, b, 'checked_at'),
		TorrentDownloadInfo.merge(a.download_info, b.download_info),
		max(a.meta_time, b.meta_time)
	)

static func from_dict(d: Dictionary):
	return Torrent.new(
		d['infohash'],
		d.get('name', default_title),
		d.get('size', 0),
		d.get('trackers', []),
		d.get('category', default_category),
		d.get('num_seeders', 0),
		d.get('num_leechers', 0),
		d.get('created', 0),
		d.get('last_tracker_check', 0),
		TorrentDownloadInfo.from_dict(d)
	)

static func from_torrent_file(content: PackedByteArray):
	var decoded = Bencode.decode(content)
	if decoded[0] != OK:
		return null
	decoded = decoded[1]
	var is_v1 = 'pieces' in decoded.get('info', {})
	var is_v2 = 'piece layers' in decoded
	# Tribler does not support V2-only torrents yet
	if is_v2 and not is_v1:
		return null
	var info = Bencode.encode(decoded['info'])
	if info == null:
		return null
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA1)
	ctx.update(info)
	var ih = ctx.finish()
	var announce = []
	if 'announce' in decoded:
		announce.push_back(decoded['announce'])
	announce.append_array(decoded.get('announce-list', []).map(
		func(a): return a[0]))
	var length = decoded['info'].get('length')
	if length == null:
		length = (decoded['info'].get('files', [])
			.map(func(f): return f['length'])
			.reduce(func(a, x): return a + x, 0))
	return Torrent.new(
		ih,
		decoded['info']['name'],
		length,
		announce
	)

func get_infohash_32():
	return Base32.encode(infohash.hex_decode())

static func from_magnet_uri(magnet: String):
	var parts = URI.parse(magnet)
	if not parts:
		return
	var query = parts['query']
	if parts['protocol'] != 'magnet' or not query:
		return
	var xt = query['xt']
	if not xt is Array:
		xt = [xt]
	var ih
	for topic in xt:
		ih = topic.split(':')
		if len(ih) != 3 or ih[0] != 'urn' or ih[1] != 'btih':
			continue
		ih = ih[2]
	var _trackers = query.get('tr', [])
	if not _trackers is Array:
		_trackers = [_trackers]
	return Torrent.new(
		ih,
		query.get('dn', default_title),
		int(query.get('xl', '0')),
		_trackers
	)

func get_magnet_uri(slim: bool=false) -> String:
	var base = 'magnet:?xt=urn:btih:' + get_infohash_32()
	if slim:
		return base
	if title and title != default_title:
		base += '&dn=' + title.uri_encode()
	if size != 0:
		base += '&xl=%d' % size
	for t in trackers:
		base += '&tr=' + t.uri_encode()
	return base
