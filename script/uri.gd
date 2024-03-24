extends Object
class_name URI

static func value_encode(v):
	if typeof(v) in [TYPE_STRING, TYPE_STRING_NAME]:
		return v.uri_encode()
	return str(v)

static func dict_from_query_string(q: String) -> Dictionary:
	var kvs = q.split('&')
	var d = {}
	for kv in kvs:
		kv = kv.split('=', true, 1)
		var key = kv[0].uri_decode()
		var val = null
		if len(kv) == 2:
			val = kv[1].uri_decode()
		if key in d:
			if not d[key] is Array:
				d[key] = [d[key]]
			d[key].push_back(val)
		else:
			d[key] = val
	return d

static func parse(uri: String):
	var protocol = uri.split(':', true, 1)
	if len(protocol) != 2:
		return null
	var rest = protocol[1]
	protocol = protocol[0]
	rest = rest.lstrip('/')
	var query = rest.split('?', true, 1)
	if len(query) == 2:
		rest = query[0]
		query = dict_from_query_string(query[1])
	else:
		query = {}
	var domain = rest.split('/', true, 1)
	if len(domain) == 2:
		rest = domain[1]
		domain = domain[0]
	else:
		domain = ''
	var path = rest
	return {
		'protocol': protocol,
		'domain': domain,
		'path': path,
		'query': query,
	}
