extends Label

@export var scoreboard_url: String = "wss://scorejam2022.webfreak.org/live"

const HighscoreEntry = preload("res://HighscoreEntry.tscn")

var _client = WebSocketPeer.new()

var submitted_score = 0

var self_user_id = -1;
var self_online_score = -1;

var put_id = -1;
var putting = false
var put_timeout = 0.2

var previous_state = WebSocketPeer.STATE_CLOSED

@export var entry_height: float = 20.0

var virtual_scoreboard = {}

func _ready():
	virtual_scoreboard[-1] = create_local_score()
	reconnect()

func _closed(was_clean = false):
	set_process(false)
	await get_tree().create_timer(1.0).timeout
	submitted_score = 0
	reconnect()

func reconnect():
	# Initiate connection to the given URL.
	_client.handshake_headers = ["Authorization: Bearer YgzU1c0LvJxOj4LtdCeX"]
	# _client.supported_protocols = ["scoreboard-v1"]
	var err = _client.connect_to_url(scoreboard_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	else:
		set_process(true)

func _on_data(packet: PackedByteArray):
	var jsonText = packet.get_string_from_utf8()
	var json = JSON.parse_string(jsonText)
	if json == null:
		print("Invalid packet: ", jsonText)
	else:
		if json.has("scores"):
			update_high_scores(json["scores"])
		elif json.has("username"):
			self_user_id = json["id"]
		elif json.has("id"):
			put_id = json["id"]
			putting = false
			process_put()
		elif json.has("error"):
			print("Server error in scoreboard: ", json["error"])
			put_id = -1
		else:
			print("Unexpected packet: ", jsonText)

func send_json(data):
	_client.send_text(JSON.stringify(data))

func _process(delta):
	_client.poll()

	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count():
			_on_data(_client.get_packet())

		put_timeout -= delta
		if put_timeout <= 0.0:
			if submitted_score != Global.score:
				process_put()
				update_local_score(virtual_scoreboard[-1])
				put_timeout = 0.3
			else:
				put_timeout = 0.05

	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		if previous_state != state:
			var code = _client.get_close_code()
			var reason = _client.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			_closed(code != -1)
			set_process(false) # Stop processing.

	if previous_state != state:
		print("WebSocket state change: ", previous_state, " -> ", state)
		previous_state = state

func process_put():
	var score = Global.score
	if put_id == -1:
		if putting:
			return
		putting = true
		submitted_score = score
		send_json({
			"op": "post",
			"score": score,
			"close": false
		})
	else:
		submitted_score = score
		send_json({
			"op": "update",
			"id": put_id,
			"score": score,
			"close": false
		})

var _state = 0
func update_high_scores(scores):
	_state += 1
	print("scores: ", scores)
	for score in scores:
		if virtual_scoreboard.has(score["id"]):
			update_score(virtual_scoreboard[score["id"]], score, _state)
		else:
			var created = create_score(score, _state)
			if created != null:
				virtual_scoreboard[score["id"]] = created
				if score["author"]["id"] == self_user_id:
					self_online_score = score["id"]

	var to_remove = []
	for id in virtual_scoreboard.keys():
		if id == -1:
			continue

		var ventry = virtual_scoreboard[id]
		if ventry.state != _state:
			to_remove.append([id, ventry])

	for pair in to_remove:
		hide_score(pair[1])
		virtual_scoreboard.erase(pair[0])

	sort_scores()

func update_score(ventry, score, state):
	if ventry.local:
		update_local_score(ventry)
	else:
		ventry.state = state
		ventry.username = score["author"]["username"]
		ventry.score = score["score"]
		ventry.closed = score["closed"]

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			Global.gotPacket()

func update_local_score(ventry):
	if self_online_score != -1 \
			and virtual_scoreboard.has(self_online_score) \
			and !virtual_scoreboard[self_online_score].overriden_by_local \
			and Global.score >= virtual_scoreboard[self_online_score].score:
		hide_score(virtual_scoreboard[self_online_score])
		virtual_scoreboard[self_online_score].overriden_by_local = true
		sort_scores()

	ventry.username = "LocalUser"
	ventry.score = Global.score

func create_score(score, state):
	if score["author"]["id"] == self_user_id and score["score"] <= Global.score:
		return null
	var ventry = HighscoreEntry.instantiate()
	ventry.target_y = (get_children().size() + 1) * entry_height
	add_child(ventry)
	update_score(ventry, score, state)
	ventry.position.y = ventry.target_y
	return ventry

func create_local_score():
	var ventry = HighscoreEntry.instantiate()
	ventry.local = true
	ventry.target_y = (get_children().size() + 1) * entry_height
	add_child(ventry)
	update_local_score(ventry)
	ventry.position.y = ventry.target_y
	return ventry

func hide_score(ventry):
	remove_child(ventry)

func sort_scores():
	var values = virtual_scoreboard.values().filter(func(v): return !v.overriden_by_local)
	var scores = range(0, values.size())
	scores.sort_custom(func(a, b): return values[a]["score"] > values[b]["score"])
	var i = 0
	for index in scores:
		i += 1
		values[index].target_y = i * entry_height
