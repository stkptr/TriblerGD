extends RefCounted
class_name TorrentDownloadInfo

var meta_time

var destination

var status
var status_int

var progress

var downloaded
var download_speed
var uploaded
var upload_speed
var eta
var ratio

var peer_count
var connected_peer_count

var seed_count
var connected_seed_count

var anonymous_download
var safe_seeding
var hops

func _init(
	_destination: String,
	_status: String,
	_status_int: int,
	_progress: float,
	_downloaded: int,
	_download_speed: int,
	_uploaded: int,
	_upload_speed: int,
	_eta: int,
	_ratio: float,
	_peer_count: int,
	_connected_peer_count: int,
	_seed_count: int,
	_connected_seed_count: int,
	_anonymous_download: bool,
	_safe_seeding: bool,
	_hops: int,
	_meta_time=null
):
	meta_time = _meta_time
	if meta_time == null:
		meta_time = Time.get_ticks_usec()
	destination = _destination
	status = _status
	status_int = _status_int
	progress = _progress
	downloaded = _downloaded
	download_speed = _download_speed
	uploaded = _uploaded
	upload_speed = _upload_speed
	eta = _eta
	ratio = _ratio
	peer_count = _peer_count
	connected_peer_count = _connected_peer_count
	seed_count = _seed_count
	connected_seed_count = _connected_seed_count
	anonymous_download = _anonymous_download
	safe_seeding = _safe_seeding
	hops = _hops

static func merge(a, b) -> TorrentDownloadInfo:
	if a == null:
		return b
	if b == null:
		return a
	return TorrentDownloadInfo.new(
		Torrent.pick_newest(a, b, 'destination'),
		Torrent.pick_newest(a, b, 'status'),
		Torrent.pick_newest(a, b, 'status_int'),
		Torrent.pick_newest(a, b, 'progress'),
		Torrent.pick_newest(a, b, 'downloaded'),
		Torrent.pick_newest(a, b, 'download_speed'),
		Torrent.pick_newest(a, b, 'uploaded'),
		Torrent.pick_newest(a, b, 'upload_speed'),
		Torrent.pick_newest(a, b, 'eta'),
		Torrent.pick_newest(a, b, 'ratio'),
		Torrent.pick_newest(a, b, 'peer_count'),
		Torrent.pick_newest(a, b, 'connected_peer_count'),
		Torrent.pick_newest(a, b, 'seed_count'),
		Torrent.pick_newest(a, b, 'connected_seed_count'),
		Torrent.pick_newest(a, b, 'anonymous_download'),
		Torrent.pick_newest(a, b, 'safe_seeding'),
		Torrent.pick_newest(a, b, 'hops'),
		max(a.meta_time, b.meta_time)
	)

static func from_dict(d: Dictionary):
	if not 'status' in d or not 'status_code' in d:
		return null
	return TorrentDownloadInfo.new(
		d['destination'],
		d['status'],
		d['status_code'],
		d['progress'],
		d['all_time_download'],
		d['speed_down'],
		d['all_time_upload'],
		d['speed_up'],
		d['eta'],
		d['all_time_ratio'],
		d['num_peers'],
		d['num_connected_peers'],
		d['num_seeds'],
		d['num_connected_seeds'],
		d['anon_download'],
		d['safe_seeding'],
		d['hops']
	)
