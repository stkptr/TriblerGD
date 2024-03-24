extends Control

func _ready():
	get_tree().root.files_dropped.connect(_on_files_dropped)

func _on_files_dropped(files):
	if $TabContainer/Downloads.add_files(files):
		var idx = $TabContainer.get_tab_idx_from_control($TabContainer/Downloads)
		$TabContainer.current_tab = idx

func _on_sign_out_pressed():
	ApiManager.host = null
	ApiManager.key = null
	get_tree().change_scene_to_file("res://gui/sign_in.tscn")
