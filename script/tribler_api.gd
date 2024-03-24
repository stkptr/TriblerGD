extends RefCounted
class_name TriblerApi

var host
var key

func _init(_host, _key):
	host = _host
	key = _key

static func build_request(_host, _key, endpoint,
		params={}, content='', method=HTTPClient.METHOD_GET):
	var url = 'http://%s%s' % [_host, endpoint]
	var headers = ['X-Api-Key: %s' % _key]
	if params:
		url += '?' + '&'.join(
			params.keys().map(func(k): return '%s=%s'% [
				k.uri_encode(), URI.value_encode(params[k])
			])
		)
	if content is Dictionary:
		content = JSON.stringify(content)
	return [url, headers, method, content]

static func static_statistics(_host, _key):
	return build_request(_host, _key, '/statistics/tribler')

func request(endpoint, params={}, content='', method=HTTPClient.METHOD_GET):
	return TriblerApi.build_request(host, key, endpoint, params, content, method)

func get_stats():
	return request('/statistics/tribler')

func get_popular_torrents():
	return request('/metadata/torrents/popular')

func get_downloads():
	return request('/downloads')

func get_settings():
	return request('/settings')

func set_settings(settings: Dictionary):
	return request('/settings', {}, settings, HTTPClient.METHOD_POST)

func search(text: String, first: int, last: int,
		include_total: bool=false,
		exclude_deleted: bool=false,
		hide_xxx: bool=false,
		sort_desc: bool=false,):
	return request('/metadata/search/local', {
		'first': first,
		#'metadata_type': [],
		'exclude_deleted': exclude_deleted,
		#'max_rowid': 0,
		'txt_filter': text,
		'last': last,
		'include_total': include_total,
		'hide_xxx': hide_xxx,
		#'category': '',
		'sort_desc': sort_desc,
		'sort_by': 'size'
	})

func download(uri: String, destination: String, hops: int, safe_seeding: bool):
	return request('/downloads', {}, {
		'safe_seeding': safe_seeding,
		'uri': uri,
		'destination': destination,
		'anon_hops': hops,
	}, HTTPClient.METHOD_PUT)

func download_infohash(infohash: String, destination: String, hops: int, safe_seeding: bool):
	var uri = Torrent.new(infohash).get_magnet_uri()
	return download(uri, destination, hops, safe_seeding)

func update_download(infohash: String, settings: Dictionary):
	return request('/downloads/%s' % infohash, {}, settings, HTTPClient.METHOD_PATCH)

func pause_download(infohash: String):
	return update_download(infohash, {
		'state': 'stop',
	})

func resume_download(infohash: String):
	return update_download(infohash, {
		'state': 'resume',
	})

func delete_download(infohash: String, remove_data: bool=false):
	return request('/downloads/%s' % infohash, {}, {
		'remove_data': remove_data
	}, HTTPClient.METHOD_DELETE)
