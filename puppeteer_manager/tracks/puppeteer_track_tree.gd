class_name PuppeteerTrackTree
extends PuppeteerBase

const ANIMATION_NODE_EMPTY := preload("./animation_node_empty.tres")
const ANIMATION_NODE_PREFIX := &"Animation_"

class TrackTarget:
	var name: StringName
	var target: float = 0.0

class BlendData:
	var node: AnimationNodeAdd2 = null
	var param: StringName
	var rate: float = 0.1 * 60
	var target: float = 0.0

signal toggle_gaze_update(toggle: bool, propagate: bool)

var animation_tree:= AnimationTree.new()

var _gaze_computation := GazeComputation.new()
var _compute_gaze := false

## Contains all blend nodes. Each element links a track_name to its corresponding node and blend rate
## Elements should be of the form StringName: BlendData
var _blend_nodes: Dictionary = {}

static func _add_add_node(blend_tree: AnimationNodeBlendTree, node_name: StringName) -> StringName:
	var add_node := AnimationNodeAdd2.new()
	blend_tree.add_node(node_name, add_node)
	return node_name

static func _add_anim_node(blend_tree: AnimationNodeBlendTree, 
						   node_name: StringName, track_name: StringName) -> StringName:
	var anim_node := AnimationNodeAnimation.new()
	anim_node.animation = track_name
	anim_node.play_mode = AnimationNodeAnimation.PLAY_MODE_FORWARD
	blend_tree.add_node(node_name, anim_node)
	return node_name

static func _add_empty_anim_node(blend_tree: AnimationNodeBlendTree, node_name: StringName) -> StringName:
	var empty_node: AnimationRootNode = ANIMATION_NODE_EMPTY.new()
	blend_tree.add_node(node_name, empty_node)
	return node_name

func _ready():
	self.add_child(self.animation_tree)
	self.animation_tree.owner = self
	
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
func initialize(animations: AnimationPlayer, blend_tracks: Array[String], reset_track: StringName = &""):
	self.animation_tree.anim_player = animations.get_path()
	var blend_tree := AnimationNodeBlendTree.new()
	
	var base_node_name: StringName = &""
	if !reset_track.is_empty():
		base_node_name = PuppeteerTrackTree._add_anim_node(blend_tree, ANIMATION_NODE_PREFIX + reset_track, reset_track)
	else:
		base_node_name = PuppeteerTrackTree._add_empty_anim_node(blend_tree, &"EmptyStart")
	
	var add_node_name: StringName = &""
	var new_anim_node_name: StringName = &""
	
	# For each track, add and connect one animation_node with the "add" port of one add_node
	# The add_node is labelled track_name, and the animation_node gets ANIMATION_NODE_PREFIX + track_name
	for track_name in blend_tracks:
		var tn = track_name.to_lower()
		add_node_name = PuppeteerTrackTree._add_add_node(blend_tree, tn)
		new_anim_node_name = PuppeteerTrackTree._add_anim_node(blend_tree, ANIMATION_NODE_PREFIX + tn, track_name)
		
		blend_tree.connect_node(add_node_name, 0, base_node_name)
		blend_tree.connect_node(add_node_name, 1, new_anim_node_name)
		
		var blend_data := BlendData.new()
		blend_data.node = blend_tree.get_node(add_node_name)
		blend_data.param = &"parameters/" + add_node_name + &"/add_amount"
		self._blend_nodes[tn] = blend_data
		
		base_node_name = add_node_name
	
	# Connect the last add node to the tree's output
	blend_tree.connect_node(&"output", 0, add_node_name)
	
	self.animation_tree.tree_root = blend_tree

func set_track_targets(track_targets: Array[TrackTarget]) -> void:
	for t in track_targets:
		var blend_data: BlendData = self._blend_nodes.get(t.name.to_lower(), null)
		if blend_data:
			blend_data.target = t.target

## Takes targets as a dictionary. Elements should be of the form String -> float (track_name -> value)
func set_track_targets_dict(track_targets: Dictionary) -> void:
	# TODO: Use key-value pairs once https://github.com/godotengine/godot-proposals/issues/3457
	# is implemented
	for vmc_name: String in track_targets:
		var blend_data: BlendData = self._blend_nodes.get(vmc_name.to_lower())
		if blend_data:
			blend_data.target = track_targets[vmc_name]

func set_track_targets_mp(track_targets: Array[MediaPipeCategory]) -> void:
	for t in track_targets:
		var blend_data: BlendData = self._blend_nodes.get(t.category_name.to_lower(), null)
		if blend_data: 
			blend_data.target = t.score

func enable_gaze_update(enable: bool):
	self.emit_signal(&"toggle_gaze_update", true, true)

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
	
	for bd: BlendData in self._blend_nodes.values():
		var add: float = lerpf(self.animation_tree.get(bd.param), bd.target, bd.rate * delta)
		self.animation_tree.set(bd.param, add)
