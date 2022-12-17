@tool
extends EditorPlugin
var dock
var fontpath
var texturepath
var texture
var input : String
var chsize : Vector2
var bmsize : Vector2
var output

func _enter_tree():
	dock = preload("res://addons/BitmapFontMaker/main.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	dock.get_node("Input").connect("text_changed",Callable(self,"counter"))
	dock.get_node("Button").connect("button_down",Callable(self,"initfont"))

func counter():
	var count : int
	count = dock.get_node("Input").text.length()
	dock.get_node("Output").text = "Character count: " + str(count) + "\n" + "Last character: " + str(dock.get_node("Input").text.unicode_at(count-1))

func initfont():
	fontpath = dock.get_node("Fontpath").text
	texturepath = dock.get_node("Texturepath").text
	input = dock.get_node("Input").text
	chsize = Vector2(dock.get_node("Dimensions/Width").value, dock.get_node("Dimensions/Height").value)
	#try:
	texture = load(texturepath)
	if texture.get_class() != "CompressedTexture2D":
		dock.get_node("Output").text = "Wrong filetype \n" + texturepath
	else:
		dock.get_node("Output").text = "Texture2D path valid"
		bmsize = Vector2(int(texture.get_size().x / chsize.x), int(texture.get_size().y / chsize.y))
		if input == "":
			dock.get_node("Output").text = "Characters field cannot be empty!"
		else:
			dock.get_node("Output").text = "Texture2D size: " + str(bmsize) + " characters"
			call("makefont")
	#else:
	#	dock.get_node("Output").text = "Invalid texture path \n" + texturepath

func makefont():
	var list = ""
	var region : Rect2
	var unicode
	var btmfont = FontFile.new()
	var count : int
	btmfont.add_texture(texture)
	for ch in input:
		region = Rect2(Vector2((count % int(bmsize.x)) * chsize.x, (int(count / bmsize.x)) * chsize.y), chsize)
		unicode = ch.unicode_at(0)
		list += String(unicode) + ", "
		btmfont.add_char(unicode,0,region)
		count += 1
	ResourceSaver.save(btmfont, fontpath)
	dock.get_node("Output").text = "Font created. List: \n" + list

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()
