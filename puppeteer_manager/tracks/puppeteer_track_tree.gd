class_name PuppeteerTrackTree
extends PuppeteerBase

signal toggle_gaze_update(toggle: bool, propagate: bool)

var _avatar_animation_tree: AvatarAnimationTree = null
var _blend_tree := AnimationNodeBlendTree.new()

var _gaze_computation := GazeComputation.new()
var _compute_gaze := false

## Contains all blend nodes. Each element links a track_name to its corresponding node and blend rate
## Elements should be of the form StringName: BlendData
var _blend_nodes: Dictionary = {}

func _ready():
	super()

func add_gui():
	var gui_menu: GuiTabMenuBase = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH).get_puppeteer_gui()
	var elements: Array[GuiElement.ElementData] = []
	
	var gaze_strength := GuiElement.ElementData.new()
	gaze_strength.Name = "Compute Gaze"
	gaze_strength.OnDataChangedCallable = func(toggle: bool): self._compute_gaze = toggle
	gaze_strength.SetDataSignal = [ self, &"toggle_gaze_update" ]
	gaze_strength.Data = GuiElement.CheckBoxData.new()
	gaze_strength.Data.Default = self._compute_gaze
	elements.append(gaze_strength)
	
	elements.append_array(self._gaze_computation.generate_gui_elements())
	
	gui_menu.add_elements_to_tab(self.name, elements)

func remove_gui():
	var gui_menu: GuiTabMenuBase = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH).get_puppeteer_gui()
	gui_menu.remove_tab(self.name)

## Initialize the animation_tree. If reset_track is set, this puppeteer will reset the puppet
## before applying any other blend_tracks.
func initialize(animation_tree: AvatarAnimationTree, 
				blend_tracks: Array[String], reset_track: StringName = &""):
	self._avatar_animation_tree = animation_tree
	self._blend_tree = AnimationNodeBlendTree.new()
	var animations: Array[AnimationNodeAnimation] = []
	for track in blend_tracks:
		animations.push_back(animation_tree.create_animation_node(track))
	var reset_anim := animation_tree.create_animation_node(reset_track) if !reset_track.is_empty() else null
	var blend_data := AvatarTrackUtils.setup_animation_tree(self._blend_tree, animations, reset_anim)
	
	var node_name := self.name
	AvatarTrackUtils.adjust_blend_data_param_to_subtree(blend_data, node_name)
	
	# Convert keys to lowercase to remove amiguity later on
	self._blend_nodes.clear()
	for k: String in blend_data.keys():
		var bd: AvatarTrackUtils.BlendData = blend_data[k]
		self._blend_nodes[k.to_lower()] = bd
	
	animation_tree.push_node(node_name, self._blend_tree)

func set_track_targets(track_targets: Array[AvatarTrackUtils.TrackTarget]) -> void:
	for t in track_targets:
		var blend_data: AvatarTrackUtils.BlendData = self._blend_nodes.get(t.name.to_lower(), null)
		if blend_data:
			blend_data.target = t.target

## Takes targets as a dictionary. Elements should be of the form String -> float (track_name -> value)
func set_track_targets_dict(track_targets: Dictionary) -> void:
	# TODO: Use key-value pairs once https://github.com/godotengine/godot-proposals/issues/3457
	# is implemented
	for vmc_name: String in track_targets:
		var blend_data: AvatarTrackUtils.BlendData = self._blend_nodes.get(vmc_name.to_lower())
		if blend_data:
			blend_data.target = track_targets[vmc_name]

func set_track_targets_mp(track_targets: Array[MediaPipeCategory]) -> void:
	for t in track_targets:
		var blend_data: AvatarTrackUtils.BlendData = self._blend_nodes.get(t.category_name.to_lower(), null)
		if blend_data: 
			blend_data.target = t.score

func enable_gaze_update(enable: bool):
	self.emit_signal(&"toggle_gaze_update", enable, true)

func set_horizontal_gaze_strength(val: float):
	self._gaze_computation.emit_signal(&"set_horizontal_gaze_strength", val, true)

func set_vertical_gaze_strength(val: float):
	self._gaze_computation.emit_signal(&"set_vertical_gaze_strength", val, true)

func update_gaze_from_perfect_sync():
	var gazes := self._gaze_computation.compute_gaze_from_blend_shapes(self._blend_nodes)
	self.set_track_targets(gazes)

func update_puppet(delta: float) -> void:
	if self._compute_gaze:
		self.update_gaze_from_perfect_sync()
	
	for bd: AvatarTrackUtils.BlendData in self._blend_nodes.values():
		var add: float = lerpf(self._avatar_animation_tree.get(bd.param), bd.target, bd.rate * delta)
		self._avatar_animation_tree.set(bd.param, add)
