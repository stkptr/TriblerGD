extends Control

@export var responsive: bool = false
@export var debug_torrent_count: int = 50
@export var hide_names: bool = false
@export var default_name: String = 'Torrent name'
@export var default_infohash: String = '0000000000000000000000000000000000000000'
var default_infohash_32 = Base32.encode(default_infohash.hex_decode())

@onready var list_node = $Split/List
@onready var torrent_details = $Split/TorrentDetails
@onready var attributes = $Split/TorrentDetails/Attributes
@onready var active_buttons = $Split/TorrentDetails/ActiveButtons
@onready var pause_button = $Split/TorrentDetails/ActiveButtons/Pause
@onready var download_buttons = $Split/TorrentDetails/DownloadButtons
@onready var download_button = $Split/TorrentDetails/DownloadButtons/Download

var list
var merged
var selected
var selected_hash

func _ready():
	download_button.disabled = not ApiManager.connected
	torrent_details.visible = false
	ActiveDownloads.updated.connect(_on_downloads_received)
	set_list(TorrentList.new([]))
	get_tree().root.size_changed.connect(_on_resize)
	_on_resize()
	if get_parent() == get_tree().root:
		debug_fill()

func debug_fill(count=debug_torrent_count):
	var crypto = Crypto.new()
	var torrents = []
	for i in range(count):
		torrents.push_back(Torrent.new(
			crypto.generate_random_bytes(20),
			'Example torrent',
			randi()
		))
	set_list(TorrentList.new(torrents))

func set_expand(node):
	node.size_flags_vertical = SIZE_EXPAND_FILL
	node.size_flags_horizontal = SIZE_EXPAND_FILL

func split_swap(split):
	var old = $Split
	old.remove_child(list_node)
	old.remove_child(torrent_details)
	remove_child(old)
	old.queue_free()
	split.name = 'Split'
	set_expand(split)
	split.add_child(list_node)
	set_expand(list_node)
	split.add_child(torrent_details)
	add_child(split)

func _on_resize():
	if not responsive:
		return
	var sz = get_tree().root.size
	var landscape = true
	if sz.x < sz.y:
		landscape = false
	if landscape and $Split is VSplitContainer:
		var container = HSplitContainer.new()
		split_swap(container)
	elif not landscape and $Split is HSplitContainer:
		var container = VSplitContainer.new()
		split_swap(container)

func _on_downloads_received(dl_list: TorrentList):
	var new_list = []
	for i in range(len(list.list)):
		var v = list.list[i]
		var corresponding = dl_list.get_infohash(v.infohash)
		if not corresponding:
			new_list.append(v)
			continue
		new_list.append(Torrent.merge(
			v, corresponding
		))
	merged = TorrentList.new(new_list)
	display_list(merged)

func display_list(_list):
	list_node.clear()
	for d in _list.list:
		list_node.add_item(default_name if hide_names else d.title)
	if selected_hash:
		var i = _list.find_infohash(selected_hash)
		if i != null:
			list_node.select(i)
			_on_list_item_selected(i)
		else:
			torrent_details.visible = false

func set_list(_list):
	list = _list
	merged = list
	display_list(list)

func humanize_time(time):
	if time < 0.5:
		return 'now'
	if time > 1000 * 365 * 24 * 60 * 60: # 1 millenia
		return 'never'
	var intervals = [
		# name, threshold, amount
		['years', 1, time / (60 * 60 * 24 * 365)],
		['days', 1, time / (60 * 60 * 24)],
		['hours', 1, time / (60 * 60)],
		['minutes', 1, time / 60],
		['seconds', 0, time]
	]
	for i in intervals:
		if i[2] >= i[1]:
			return '%d %s' % [i[2], i[0]]

func _on_list_item_selected(index):
	torrent_details.visible = true
	selected = merged.list[index]
	selected_hash = selected['infohash']
	var dlinfo = selected.download_info
	if dlinfo:
		pause_button.text = ('Pause' if dlinfo.status in [
			'CIRCUITS', 'METADATA', 'DOWNLOADING', 'SEEDING'
		] else 'Resume')
		pause_button.disabled = dlinfo.status in [
			'CIRCUITS', 'METADATA', 'SEEDING'
		]
	attributes.clear()
	attributes.add_text((
	  'Name: %s\n\n'
	+ 'Infohash: %s\n'
	+ 'Infohash-32: %s\n'
	+ 'Size: %s (%d bytes)\n'
	) % [
		default_name if hide_names else selected.title,
		default_infohash if hide_names else selected.infohash,
		default_infohash_32 if hide_names else selected.get_infohash_32(),
		String.humanize_size(selected.size), selected.size,
	])
	if not dlinfo:
		active_buttons.visible = false
		download_buttons.visible = true
	else:
		active_buttons.visible = true
		download_buttons.visible = false
		attributes.add_text((
		  '\nStatus: %s\n'
		+ 'Destination: %s\n'
		+ 'Anonymous DL: %s, safe seeding: %s (%d hops)\n'
		+ 'Speed: %s/s up, %s/s down\n'
		+ 'Progress: %.02f%%\n'
		+ 'ETA: %s\n'
		+ 'Download: %s, upload: %s (ratio: %.02f%%)\n'
		+ 'Peers: %d (%d), seeders: %d (%d)\n'
		) % [
			dlinfo.status.to_lower(),
			dlinfo.destination,
			str(dlinfo.anonymous_download), str(dlinfo.safe_seeding), dlinfo.hops,
			String.humanize_size(dlinfo.upload_speed), String.humanize_size(dlinfo.download_speed),
			dlinfo.progress * 100,
			humanize_time(dlinfo.eta) if dlinfo.status == 'DOWNLOADING' else 'never',
			String.humanize_size(dlinfo.downloaded),
			String.humanize_size(dlinfo.uploaded),
			dlinfo.ratio * 100,
			dlinfo.connected_peer_count, dlinfo.peer_count,
			dlinfo.connected_seed_count, dlinfo.seed_count,
		])

func _on_pause_pressed():
	if selected.download_info.status == 'DOWNLOADING':
		ActiveDownloads.pause(selected.infohash)
	else:
		ActiveDownloads.resume(selected.infohash)

func _on_delete_pressed():
	ActiveDownloads.delete(selected.infohash)

func _on_download_pressed():
	ActiveDownloads.add(selected.infohash)

func _on_copy_pressed():
	DisplayServer.clipboard_set(selected.get_magnet_uri())

func _on_slim_pressed():
	DisplayServer.clipboard_set(selected.get_magnet_uri(true))
