extends Node

@export var equippedPackages: int = 0
@export var canInteract: bool = 0 : set = setCanInteract
@export var score: int = 0

@export var username: String = "Anonymous"
@export var authToken: String = ""
@export var userId: int = -1

func _ready():
	pass # Replace with function body.

func equipPackage():
	if equippedPackages < 5:
		equippedPackages += 1
		return true
	return false

func dropPackage():
	if equippedPackages > 0:
		equippedPackages -= 1

func setCanInteract(v):
	canInteract = v

func gotPacket():
	score += 1000

func set_user(username, password):
	if username == "":
		username = "Anonymous"

	if password == null:
		self.username = username
		if self.authToken != "":
			_logout()

		return {"success": true}
	else:
		if self.username == username and self.authToken != "":
			return {"success": true}

		if self.authToken != "":
			_logout()
		
		return await _login(username, password)

func _logout():
	# TODO: invalidate token on server
	self.authToken = ""
	self.userId = -1

func _login(username, password):
	self.username = username
	var res = await _make_post_request("/login", {
		"username": username,
		"password": password
	});
	_process_auth(res)
	return res

func register(username, password):
	self.username = username
	var res = await _make_post_request("/register", {
		"username": username,
		"password": password
	});
	_process_auth(res)
	return res

func _make_post_request(endpoint, data_to_send):
	# Convert data to json string:
	var http = HTTPRequest.new()
	add_child(http)
	var query = JSON.stringify(data_to_send)
	var headers = ["Content-Type: application/json"]
	http.request("https://scorejam2022.webfreak.org" + endpoint, headers, true, HTTPClient.METHOD_POST, query)
	var res = await http.request_completed;
	var result: int = res[0]
	var response_code: int = res[1]
	var retHeaders: PackedStringArray = res[2]
	var body: Variant = res[3].get_string_from_utf8()
	if body != "" and body[0] == '{':
		body = JSON.parse_string(body)
	else:
		body = {"raw": body}
	
	return {
		"success": response_code == 200,
		"error": null \
			if response_code < 400 else \
			body["statusMessage"],
		"data": body
	}

func _process_auth(res):
	if res["success"]:
		self.authToken = res["data"]["token"]
		self.userId = res["data"]["id"]
	else:
		self.authToken = ""
		self.userId = -1

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
