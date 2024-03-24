extends Control

@onready var warning = $CenterContainer/VBoxContainer/Warning

var host
var key
var can_connect = false

func change():
	ApiManager.host = host
	ApiManager.key = key
	get_tree().change_scene_to_file("res://gui/main_ui.tscn")

func submit():
	host = $CenterContainer/VBoxContainer/Host.text
	key = $CenterContainer/VBoxContainer/Key.text
	ApiManager.rest.schedule(
			TriblerApi.static_statistics(host, key)
	).connect(_on_statistics_received)

func _on_statistics_received(response_code, json):
	if 200 <= response_code and response_code < 300:
		change()
		return
	can_connect = false
	if json:
		warning.text = 'Error: %s' % JSON.parse_string(json)['error']
	else:
		warning.text = 'Error: invalid host'

func _on_host_text_submitted(_new_text):
	submit()

func _on_key_text_submitted(_new_text):
	submit()

func _on_connect_pressed():
	if can_connect:
		submit()

func _on_host_focus_exited():
	var address = $CenterContainer/VBoxContainer/Host.text.rsplit(':')
	can_connect = false
	if len(address) < 2:
		warning.text = 'Missing port'
		return
	var _port = address[1]
	var _host = address[0]
	if not _port.is_valid_int() or int(_port) > 65535:
		warning.text = 'Invalid port'
		return
	if not _host in ['localhost', '127.0.0.1', '[::1]']:
		warning.text = 'Host is remote: consider using SSH tunneling for a secure connection'
		can_connect = true
		return
	can_connect = true
	warning.text = ''
