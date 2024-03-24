extends Control

@onready var add_menu = $VSplitContainer/AddMenu
@onready var add_button = $VSplitContainer/AddMenu/Add
@onready var uri_boxes = $VSplitContainer/AddMenu/URIs
@onready var torrent_list = $VSplitContainer/VBoxContainer/TorrentList

const uri_box = preload("res://gui/uri_box.tscn")

func _ready():
	ActiveDownloads.updated.connect(torrent_list.set_list)
	add_button.disabled = not ApiManager.connected
	if get_parent() == get_tree().root:
		get_tree().root.files_dropped.connect(add_files)
	if not ApiManager.connected:
		torrent_list.debug_fill()

func _on_add_torrent_pressed():
	add_menu.visible = not add_menu.visible

func _on_add_pressed():
	add_menu.visible = false
	for uri in uri_boxes.get_children():
		if uri.text != '':
			ActiveDownloads.add(uri.text)
		uri.text = ''
		uri.queue_free()
	uri_boxes.add_child(uri_box.instantiate())

func update_boxes(adjust=0):
	var multi = uri_boxes.get_child_count() + adjust > 1
	add_button.text = 'Add all' if multi else 'Add'
	var removable = uri_boxes.get_child_count
	for n in uri_boxes.get_children():
		n.removable = multi

func populate_uri_new(uri: String):
	add_menu.visible = true
	for n in uri_boxes.get_children():
		if n.text == '':
			n.text = uri
			return
	var box = uri_box.instantiate()
	box.text = uri
	box.removable = true
	uri_boxes.add_child(box)
	update_boxes()

func _on_uris_child_exiting_tree(_node):
	update_boxes(-1)

func add_files(files):
	var has_added = false
	for f in files:
		var content = FileAccess.get_file_as_bytes(f)
		var torrent = Torrent.from_torrent_file(content)
		if torrent:
			populate_uri_new(torrent.get_magnet_uri())
			has_added = true
	return has_added

func _on_file_uri_pressed():
	var fd = FileDialog.new()
	fd.set_filters(PackedStringArray(["*.torrent ; Torrent files"]))
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.files_selected.connect(add_files)
	add_child(fd)
	fd.popup_centered_ratio()
