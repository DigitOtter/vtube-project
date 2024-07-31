extends Node

const ASSETS_DIR: String = "res://assets"

signal available_assets_changed(assets: Array[String])

var available_assets: Array[String]

var file_type_loads: Dictionary = {
	".png": self._load_png,
	".tscn": self._load_tscn,
	".tscn.remap": self._load_tscn_remap
}

func _ready():
	self.available_assets.clear()
	
	# Find all stored assets
	var asset_dir = DirAccess.open(ASSETS_DIR)
	for file in asset_dir.get_files():
		var file_path: String = ASSETS_DIR + "/" + file
		for type in self.file_type_loads.keys():
			if file_path.ends_with(type):
				self.available_assets.append(file_path)

func _load_png(file_path: String) -> Sprite3D:
	var png_texture: Texture2D = null
	if file_path.begins_with("res://"):
		png_texture = load(file_path)
	else:
		var img: Image = Image.load_from_file(file_path)
		png_texture = ImageTexture.create_from_image(img)
	
	var sprite_3d: Sprite3D = Sprite3D.new()
	sprite_3d.texture = png_texture
	
	return sprite_3d

func _load_tscn(file_path: String) -> Node3D:
	return load(file_path).instantiate()

func _load_tscn_remap(file_path: String) -> Node3D:
	const REMAP := &".remap"
	var scene_file_path := file_path.erase(file_path.length()-REMAP.length(), REMAP.length())
	return self._load_tscn(scene_file_path)

func list_available_assets() -> Array[String]:
	return self.available_assets

func add_file(file_path: String):
	if !self.available_assets.has(file_path):
		self.available_assets.append(file_path)
		self.emit_signal("available_assets_changed", self.available_assets)

func load_asset(file_path: String) -> Node3D:
	# Load file with the appropriate loader
	for type in self.file_type_loads.keys():
		if file_path.ends_with(type):
			return self.file_type_loads[type].call(file_path)
	
	return null
