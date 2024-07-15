#class_name PuppeteerManager
extends Node

const PUPPETEER_MANAGER_NODE_PATH: NodePath = "/root/PuppeteerManager"
const EMOTION_CONTROL_NODE_NAME := &"Emotion Control"

enum PuppeteerType {
	SKELETON,
	BLEND_SHAPES
}

signal puppeteer_ready(avatar_root: Node)
signal toggle_emotion_control(enable: bool, propagate: bool)

## Should have the form TrackerBase: Array[ PuppeteerBase ]
var _registered_trackers: Dictionary = {}

var _puppeteers:    Array[PuppeteerBase] = []

var _puppeteer_gui_menu := Gui.GUI_TAB_MENU_SCENE.instantiate()
var _emotion_control_enabled: bool = false

## This function is connected to each tracker's tree_exiting signal
func _on_tracker_exit(tracker: TrackerBase):
	self.remove_tracker_puppeteers(tracker)

## Remove puppeteer from tree and from _puppeteers. Should be called after all references to
## puppeteer have been removed from _registered_trackers.
func _remove_puppeteer_from_tree(puppeteer: PuppeteerBase):
	puppeteer.owner = null
	if puppeteer.get_parent() == self:
		self.remove_child(puppeteer)
	self._puppeteers.erase(puppeteer)
	puppeteer.queue_free()

func _get_or_add_tracker(tracker: TrackerBase) -> Array:
	var reg_puppeteers = self._registered_trackers.get(tracker)
	if not reg_puppeteers:
		reg_puppeteers = []
		self._registered_trackers[tracker] = reg_puppeteers
		
		# Ensure that puppeteers are removed when the associated tracker is deleted
		tracker.connect(&"tree_exiting", func(): self._on_tracker_exit(tracker))
	
	return reg_puppeteers

func _setup_emotion_control(avatar_root: Node):
	var emotion_puppeteer: PuppeteerTrackEmotion = self.find_child(EMOTION_CONTROL_NODE_NAME, false)
	if emotion_puppeteer:
		self.remove_puppeteer(emotion_puppeteer)
	if not self._emotion_control_enabled or not avatar_root:
		return
	
	emotion_puppeteer = self.request_new_puppeteer(null, 
												   PuppeteerBase.Type.TRACK_EMOTION, 
												   EMOTION_CONTROL_NODE_NAME)
	emotion_puppeteer.name = EMOTION_CONTROL_NODE_NAME
	self.move_child(emotion_puppeteer, -1)
	
	var anim_player: AnimationPlayer = avatar_root.find_child("AnimationPlayer", true)
	
	# Find avatar's emotions
	var available_emotions: Array[String] = []
	var track_names := anim_player.get_animation_list()
	var emotion_list := PuppeteerTrackEmotion.DEFAULT_EMOTION_NAMES
	for tn in track_names:
		if tn.to_lower() in emotion_list:
			available_emotions.append(tn)

	emotion_puppeteer.initialize(anim_player, available_emotions)

func _on_avatar_loaded(avatar_root: Node):
	self.emit_signal(&"puppeteer_ready", avatar_root)
	
	self._setup_emotion_control(avatar_root)

func _on_emotion_control_toggled(enabled: bool):
	self._emotion_control_enabled = enabled
	
	var main: Main = get_node(Main.MAIN_NODE_PATH)
	if main.is_avatar_loaded():
		self._setup_emotion_control(main.get_avatar_root_node())

func _init_gui():
	var gui_menu: GuiTabMenuBase = get_node(Gui.GUI_NODE_PATH).get_gui_menu()
	var elements: Array[GuiElement.ElementData] = []
	
	var puppeteer_emotion_control := GuiElement.ElementData.new()
	puppeteer_emotion_control.Name = "Emotion Toggles"
	puppeteer_emotion_control.OnDataChangedCallable = self._on_emotion_control_toggled
	puppeteer_emotion_control.SetDataSignal = [ self, &"toggle_emotion_control" ]
	puppeteer_emotion_control.Data = GuiElement.CheckBoxData.new()
	puppeteer_emotion_control.Data.Default = self._emotion_control_enabled
	elements.append(puppeteer_emotion_control)
	
	var puppeteer_menu_data := GuiElement.ElementData.new()
	puppeteer_menu_data.Name = "Puppeteer Settings"
	puppeteer_menu_data.Data = GuiElement.GuiTabMenuData.new()
	puppeteer_menu_data.Data.GuiTabMenuNode = self._puppeteer_gui_menu 
	elements.append(puppeteer_menu_data)
	
	gui_menu.add_elements_to_tab("Puppeteers", elements)

func _ready():
	var main_node: Main = get_node(Main.MAIN_NODE_PATH)
	main_node.connect_avatar_loaded(self._on_avatar_loaded)
	
	self._init_gui()

func _process(delta):
	# Process all puppeteers in order
	for p in self._puppeteers:
		p.update_puppet(delta)

func request_new_puppeteer(
		tracker: TrackerBase, 
		type: PuppeteerBase.Type,
		puppeteer_name: String) -> PuppeteerBase:
	var tracker_name: String = tracker.name if tracker else ""
	var new_puppeteer: PuppeteerBase = PuppeteerBase.create_new(type, tracker_name, puppeteer_name)
	if not new_puppeteer:
		return null
	
	if tracker:
		var reg_puppeteers = self._get_or_add_tracker(tracker)
		reg_puppeteers.append(new_puppeteer)
	
	self._puppeteers.append(new_puppeteer)
	
	self.add_child(new_puppeteer)
	new_puppeteer.owner = self
	
	return new_puppeteer

func remove_puppeteer(puppeteer: PuppeteerBase):
	# Remove from registered trackers
	for tpups: Array in self._registered_trackers.values():
		tpups.erase(puppeteer)
	
	self._remove_puppeteer_from_tree(puppeteer)

func remove_tracker_puppeteers(tracker: TrackerBase):
	var reg_puppeteers = self._registered_trackers.get(tracker, [])
	self._registered_trackers.erase(tracker)
	
	for p in reg_puppeteers:
		self._remove_puppeteer_from_tree(p)

func update_puppeteer_order():
	# TODO
	pass

func get_puppeteer_gui() -> GuiTabMenuBase:
	return self._puppeteer_gui_menu
