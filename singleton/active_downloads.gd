extends Node

signal updated(list: TorrentList)

var list = TorrentList.new([])
var auto_refresh = true
var refresh_interval = 1

var download_defaults

func _ready():
	refresh_loop()

func update():
	if ApiManager.connected:
		ApiManager.rest.schedule(
			ApiManager.api.get_downloads()
		).connect(_on_downloads_received)
		ApiManager.rest.schedule(
			ApiManager.api.get_settings()
		).connect(_on_settings_received)

func _on_downloads_received(_response_code, json):
	list = TorrentList.from_dict_array(json['downloads'])
	updated.emit(list)

func _on_settings_received(_response_code, json):
	download_defaults = json['settings']['download_defaults']

func refresh_loop():
	if auto_refresh:
		update()
	get_tree().create_timer(refresh_interval).timeout.connect(refresh_loop)

func get_default(attribute, desired):
	if desired == null:
		return download_defaults[attribute]
	return desired

func get_default_destination(desired):
	return get_default('saveas', desired)

func get_default_hops(desired):
	return get_default('number_hops', desired)

func add_infohash(infohash: String, destination=null):
	destination = get_default_destination(destination)
	ApiManager.rest.schedule(ApiManager.api.download_infohash(
		infohash, destination, get_default_hops(null), true
	))
	update()

func add_uri(uri: String, destination=null):
	destination = get_default_destination(destination)
	# this converts hex infohashes to base32 infohashes
	var torrent = Torrent.from_magnet_uri(uri)
	if torrent:
		uri = torrent.get_magnet_uri()
	ApiManager.rest.schedule(ApiManager.api.download(
		uri, destination, get_default_hops(null), true
	))
	update()

func add(uri_or_infohash: String, destination=null):
	if ':' in uri_or_infohash:
		add_uri(uri_or_infohash, destination)
	else:
		add_infohash(uri_or_infohash, destination)

func pause(infohash: String):
	ApiManager.rest.schedule(ApiManager.api.pause_download(infohash))
	update()

func resume(infohash: String):
	ApiManager.rest.schedule(ApiManager.api.resume_download(infohash))
	update()

func delete(infohash: String):
	ApiManager.rest.schedule(ApiManager.api.delete_download(infohash))
	update()
