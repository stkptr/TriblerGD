extends Control

var scrobbler = 0
var scrobble = 50
var total
var search_text

var categories = [
	'All categories'
]

func _ready():
	for c in categories:
		$VBoxContainer/HBoxContainer2/Category.add_item(c)
	if not ApiManager.connected:
		$VBoxContainer/HBoxContainer/Search.disabled = true
		$VBoxContainer/HBoxContainer/Previous.disabled = true
		$VBoxContainer/HBoxContainer/Next.disabled = true

func update_search():
	ApiManager.rest.schedule(ApiManager.api.search(
		search_text, scrobbler, scrobbler + scrobble,
		true,
		$VBoxContainer/HBoxContainer2/Deleted.button_pressed,
		$VBoxContainer/HBoxContainer2/NSFW.button_pressed,
		$VBoxContainer/HBoxContainer2/Descending.button_pressed
	)).connect(_on_search_receive)

func do_search():
	search_text = $VBoxContainer/HBoxContainer/SearchText.text
	scrobbler = 0
	update_search()

func _on_search_pressed():
	do_search()

func _on_search_text_text_submitted(_new_text):
	if ApiManager.connected:
		do_search()

func _on_next_pressed():
	if total and scrobbler + scrobble < total:
		scrobbler += scrobble
		update_search()

func _on_previous_pressed():
	if total and scrobbler:
		scrobbler = max(0, scrobbler - scrobble)
		update_search()

func _on_search_receive(_response_code, json):
	total = json['total']
	$VBoxContainer/Label.text = '%d-%d of %d' % [
		json['first'], min(json['last'], total), total
	]
	$VBoxContainer/TorrentList.set_list(TorrentList.from_dict_array(json['results']))
