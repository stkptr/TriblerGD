extends Control

func refresh():
	ApiManager.rest.schedule(
		ApiManager.api.get_popular_torrents(),
	).connect(_on_popular_received)

func _on_popular_received(_response_code, json):
	$VBoxContainer/TorrentList.set_list(TorrentList.from_dict_array(json['results']))

func _ready():
	if ApiManager.connected:
		refresh()
	else:
		$VBoxContainer/TorrentList.debug_fill()
	$VBoxContainer/Refresh.disabled = not ApiManager.connected

func _on_refresh_pressed():
	refresh()
