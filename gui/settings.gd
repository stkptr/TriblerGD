extends Control

@onready var tree = $VBoxContainer/Tree

const ranges = {
	# integral, min, max
	'port': [true, -1, 65535],
	'hops': [true, 0, 3],
	'circuits': [true, 1, 20],
	'ratio': [false, 0, 10],
	'interval': [false, 0, 60],
	'timeout': [false, 0, 60],
	'time': [false, 0, 1600],
	'rate': [true, 0, 10000000],
	'size': [true, 0, 4096],
	'download': [true, 0, 100], # connections
	'priority': [true, 0, 20],
	'type': [true, 0, 10], # this should be a dropdown
	'limit': [true, 0, 10],
}

var last_settings
var changed_settings = {}

func refresh():
	ApiManager.rest.schedule(ApiManager.api.get_settings()).connect(_on_settings_received)

func _ready():
	if ApiManager.connected:
		refresh()
	else:
		$VBoxContainer/Buttons/Refresh.disabled = true
		$VBoxContainer/Buttons/Clear.disabled = true
		$VBoxContainer/Buttons/Apply.disabled = true

func recurse_settings(path, root, d, c):
	for k in d:
		var v = d[k]
		var cv = {}
		if k in c:
			cv = c[k]
		var node: TreeItem = tree.create_item(root)
		var npath = path + '.' + k
		if v is Dictionary:
			node.set_text(0, k)
			recurse_settings(npath, node, v, cv)
		if not cv is Dictionary:
			v = cv
		if v is bool:
			node.set_metadata(0, npath)
			node.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
			node.set_checked(0, v)
			node.set_text(0, k)
		elif v is String or v == null:
			var sub = node.create_child()
			node.set_text(0, k)
			sub.set_metadata(0, npath)
			sub.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
			sub.set_text(0, str(v))
			sub.set_editable(0, true)
		elif v is float:
			var sub = node.create_child()
			node.set_text(0, k)
			sub.set_cell_mode(0, TreeItem.CELL_MODE_RANGE)
			sub.set_metadata(0, npath)
			var split = k.rsplit('_', 1)
			var nrange = ranges.get(split[-1])
			if nrange:
				var step = 1.0 if nrange[0] else 0.1
				sub.set_range_config(0, nrange[1], nrange[2], step)
				sub.set_range(0, v)
				sub.set_editable(0, true)

func display_settings(settings):
	tree.clear()
	var root = tree.create_item()
	tree.hide_root = true
	recurse_settings('', root, settings, changed_settings)

func _on_settings_received(_response_code, json):
	last_settings = json['settings']
	display_settings(last_settings)

func _on_refresh_pressed():
	refresh()

func _on_clear_pressed():
	changed_settings = {}
	display_settings(last_settings)

func _on_apply_pressed():
	ApiManager.rest.schedule(ApiManager.api.set_settings(changed_settings))
	changed_settings = {}
	refresh()

func set_dot(d: Dictionary, dot: String, v):
	var keys: Array = dot.split('.', false)
	var final = keys[-1]
	for k in keys.slice(0, len(keys) - 1):
		if not k in d:
			d[k] = {}
		d = d[k]
	d[final] = v

func _on_tree_item_edited():
	var item: TreeItem = tree.get_edited()
	var path = item.get_metadata(0)
	var mode = item.get_cell_mode(0)
	var val
	if mode == TreeItem.CELL_MODE_RANGE:
		val = item.get_range(0)
	elif mode == TreeItem.CELL_MODE_STRING:
		val = item.get_text(0)
		if val == '<null>':
			val = null
	else:
		return
	set_dot(changed_settings, path, val)

func _on_tree_item_activated():
	var item: TreeItem = tree.get_selected()
	var path = item.get_metadata(0)
	if item.get_cell_mode(0) == TreeItem.CELL_MODE_CHECK:
		item.set_checked(0, not item.is_checked(0))
		set_dot(changed_settings, path, item.is_checked(0))
