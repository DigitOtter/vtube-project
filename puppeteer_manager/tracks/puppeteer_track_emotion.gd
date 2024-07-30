class_name PuppeteerTrackEmotion
extends PuppeteerBase

## Elements must be lower-case
const DEFAULT_EMOTION_NAMES: Array[String] = [
	"angry",
	"happy",
	"sad",
	# TODO: Complete list with default emotions
]

signal emotion_toggle(emotion_name: String, enabled: bool, propagate: bool)

## Contains all blend nodes. Each element links a track_name to its corresponding node and blend rate
## Elements should be of the form StringName: BlendData
var _blend_nodes: Dictionary = {}

var _blend_tree := AnimationNodeBlendTree.new()

func _ready():
	super()

func add_gui():
	var gui_menu: GuiTabMenuBase = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH).get_puppeteer_gui()
	gui_menu.get_or_create_tab(self.name)
	#gui_menu.add_elements_to_tab(self.name, elements)

func remove_gui():
	var gui_menu: GuiTabMenuBase = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH).get_puppeteer_gui()
	gui_menu.remove_tab(self.name)

func _add_emotion_to_gui(emotion_name: String, enabled_by_default: bool = false):
	# Create new signal for this emotion
	var signal_name := "emotion_{}_toggle".format([emotion_name], "{}")
	self.add_user_signal(signal_name,[
		{ "name": "enable",    "type": TYPE_BOOL },
		{ "name": "propagate", "type": TYPE_BOOL },
	])
	# Connect to emotion_toggle
	self.connect(signal_name, 
		func(enabled: bool, propagate: bool): 
			self.emit_signal(&"emotion_toggle", emotion_name, enabled, propagate))
	
	var emotion_toggle_data := GuiElement.ElementData.new()
	emotion_toggle_data.Name = emotion_name
	emotion_toggle_data.OnDataChangedCallable = func(enabled: bool):
		self._on_emotion_toggled(emotion_name, enabled)
	emotion_toggle_data.SetDataSignal = [ self, signal_name ]
	emotion_toggle_data.Data = GuiElement.CheckBoxData.new()
	emotion_toggle_data.Data.Default = enabled_by_default
	
	var gui_menu: GuiTabMenuBase = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH).get_puppeteer_gui()
	gui_menu.add_element_to_tab(self.name, emotion_toggle_data)

func _on_emotion_toggled(emotion_name: String, enabled: bool):
	var emotion_node: TrackUtils.BlendData = self._blend_nodes.get(emotion_name, null)
	if emotion_node:
		emotion_node.target = 1.0 if enabled else 0.0

## Initialize the animation_tree. If reset_track is set, this puppeteer will reset the puppet
## before applying any other blend_tracks.
func initialize(animation_tree: AvatarAnimationTree, 
				emotion_tracks: Array[String], reset_track: StringName = &""):
	self._blend_tree = AnimationNodeBlendTree.new()
	var animations: Array[AnimationNodeAnimation] = []
	for track in emotion_tracks:
		var anim := animation_tree.create_animation_node(track)
		animations.push_back(anim)
	
	var reset_anim := animation_tree.create_animation_node(reset_track) if !reset_track.is_empty() \
						else null
	
	self._blend_nodes = TrackUtils.setup_animation_tree(self._blend_tree, animations, reset_anim)
	
	for track in emotion_tracks:
		self._add_emotion_to_gui(track, false)
	
	animation_tree.push_node(self.name, self._blend_tree)

func set_track_targets(track_targets: Array[TrackUtils.TrackTarget]) -> void:
	for t in track_targets:
		var blend_data: TrackUtils.BlendData = self._blend_nodes.get(t.name.to_lower(), null)
		if blend_data:
			blend_data.target = t.target

func update_puppet(delta: float) -> void:
	for bd: TrackUtils.BlendData in self._blend_nodes.values():
		var add: float = lerpf(self.animation_tree.get(bd.param), bd.target, bd.rate * delta)
		self.animation_tree.set(bd.param, add)
