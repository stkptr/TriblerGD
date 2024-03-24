extends Node
class_name RestRequest

var scheduled = []
var active_signal

class Signaler:
	signal received(response_code: int, json: Variant)

func act_on(params):
	$HTTPRequest.request(params[0], params[1], params[2], params[3])

func run_scheduled():
	if len(scheduled) and active_signal == null:
		var next = scheduled.pop_front()
		active_signal = next[1]
		act_on(next[0])

func schedule(params):
	var signaler = Signaler.new()
	scheduled.push_back([params, signaler])
	run_scheduled()
	return signaler.received

func _ready():
	$HTTPRequest.request_completed.connect(_on_request_completed)

func _on_request_completed(_result, response_code, _headers, body):
	var json = body.get_string_from_utf8()
	if 200 <= response_code and response_code < 300:
		json = JSON.parse_string(json)
	active_signal.received.emit(response_code, json)
	active_signal = null
	run_scheduled()
