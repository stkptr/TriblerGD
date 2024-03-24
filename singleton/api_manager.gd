extends Node

var api: TriblerApi
@onready var rest: RestRequest = $RestRequest

var host: set = set_host, get = get_host
var key: set = set_key, get = get_key

var connected:
	get: return host != null and key != null

func refresh_api():
	api = TriblerApi.new(host, key)

func _ready():
	refresh_api()

func set_host(new_host):
	host = new_host
	refresh_api()

func get_host():
	return host

func set_key(new_key):
	key = new_key
	refresh_api()

func get_key():
	return key
