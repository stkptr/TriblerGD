extends HBoxContainer

@export var removable: bool = false

var text:
	get: return $URI.text
	set(new_text): $URI.text = new_text

func _on_remove_pressed():
	if removable:
		queue_free()
	else:
		text = ''
