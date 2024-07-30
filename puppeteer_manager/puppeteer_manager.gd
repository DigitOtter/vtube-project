## Puppeteer control. Manages active puppeteers.
##
## Trackers can use various puppeteers to control avatars. When a new tracker is instantiated,
## it should request new puppeteers with [method request_new_puppeteer]. The new puppeteers are
## added as child nodes to [PuppeteerManager]. If multiple trackers are active, the puppeteers
## are executed in tracker registration oder.
##
## [PuppeteerManager] also instantiates an emotion control puppeteer that runs after the tracker
## puppeteers.
#class_name PuppeteerManager
extends Node

const PUPPETEER_MANAGER_NODE_PATH: NodePath = "/root/PuppeteerManager"
const EMOTION_CONTROL_NAME := &"Emotion Control"
const ANIMATION_TREE_NAME := &"PuppeteerTree"

enum PuppeteerType {
	SKELETON,
	BLEND_SHAPES
}

signal puppeteer_ready(avatar_base: AvatarBase)
signal toggle_emotion_control(enable: bool, propagate: bool)

## Should have the form TrackerBase: Array[ PuppeteerBase ]
var _registered_trackers: Dictionary = {}

var _puppeteer_gui_menu := Gui.GUI_TAB_MENU_SCENE.instantiate()
var _emotion_control_enabled: bool = false

## Puppeteers that should run before all trackers
var _pre_puppeteers: TrackerEmpty = TrackerBase.create_new(TrackerBase.Type.EMPTY)
var _track_reset: PuppeteerTrackReset = null

## Puppeteers that should run after all trackers
var _post_puppeteers: TrackerEmpty = TrackerBase.create_new(TrackerBase.Type.EMPTY)
var _emotion_puppeteer: PuppeteerTrackEmotion = null

## This function is connected to each tracker's tree_exiting signal
func _on_tracker_exit(tracker: TrackerBase):
	self.remove_tracker_puppeteers(tracker)

## Remove puppeteer from tree. Should be called after all references to
## puppeteer have been removed from _registered_trackers.
func _remove_puppeteer_from_tree(puppeteer: PuppeteerBase):
	puppeteer.owner = null
	if puppeteer.get_parent() == self:
		self.remove_child(puppeteer)
	puppeteer.queue_free()

func _get_or_add_tracker(tracker: TrackerBase) -> Array[PuppeteerBase]:
	var reg_puppeteers = self._registered_trackers.get(tracker, null)
	if reg_puppeteers == null:
		reg_puppeteers = [] as Array[PuppeteerBase]
		self._registered_trackers[tracker] = reg_puppeteers
		
		# Ensure that puppeteers are removed when the associated tracker is deleted
		tracker.connect(&"tree_exiting", func(): self._on_tracker_exit(tracker))
		
		# Ensure that post_puppeteers are placed after other trackers
		var puppeteers = self._registered_trackers.get(self._post_puppeteers, [] as Array[PuppeteerBase])
		self._registered_trackers.erase(self._post_puppeteers)
		self._registered_trackers[self._post_puppeteers] = puppeteers
	
	return reg_puppeteers

func _setup_track_reset(avatar_base: AvatarBase):
	if self._track_reset:
		self.remove_puppeteer(self._track_reset)
		self._track_reset = null
	if not avatar_base:
		return
	
	self._track_reset = self.request_new_puppeteer(self._pre_puppeteers,
												   PuppeteerBase.Type.TRACK_RESET,
												   "TrackReset")
	var anim_tree: AvatarAnimationTree = avatar_base.get_animation_tree()
	self._track_reset.initialize(anim_tree, &"RESET")

func _setup_emotion_control(avatar_base: AvatarBase):
	if self._emotion_puppeteer:
		self.remove_puppeteer(self._emotion_puppeteer)
		self._emotion_puppeteer = null
	if not self._emotion_control_enabled or not avatar_base:
		return
	
	self._emotion_puppeteer = self.request_new_puppeteer(self._post_puppeteers, 
														 PuppeteerBase.Type.TRACK_EMOTION, 
														 EMOTION_CONTROL_NAME)
	
	var anim_player: AnimationPlayer = avatar_base.get_animation_player()
	var anim_tree: AvatarAnimationTree = avatar_base.get_animation_tree()
	
	# Find avatar's emotions
	var available_emotions: Array[String] = []
	var track_names := anim_player.get_animation_list()
	var emotion_list := PuppeteerTrackEmotion.DEFAULT_EMOTION_NAMES
	for tn in track_names:
		if tn.to_lower() in emotion_list:
			available_emotions.append(tn)

	self._emotion_puppeteer.initialize(anim_tree, available_emotions)

func _on_avatar_loaded(avatar_base: AvatarBase):
	self.emit_signal(&"puppeteer_ready", avatar_base)
	
	self._setup_emotion_control(avatar_base)

func _on_emotion_control_toggled(enabled: bool):
	self._emotion_control_enabled = enabled
	
	# TODO: For now, we're only loading one avatar, but future use should select the correct avatar
	var main: Main = get_node(Main.MAIN_NODE_PATH)
	if main.is_avatar_loaded():
		self._setup_emotion_control(main.get_avatar_root_node().get_avatars()[0])

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
	
	self._pre_puppeteers.name = &"Pre"
	self.add_tracker(self._pre_puppeteers)
	
	self._post_puppeteers.name = &"Post"
	self.add_tracker(self._post_puppeteers)
	
	self._init_gui()

func _process(delta):
	# Process all puppeteers in order
	for p: PuppeteerBase in self.get_children():
		p.update_puppet(delta)

func add_tracker(tracker: TrackerBase):
	self._get_or_add_tracker(tracker)

func request_new_puppeteer(
		tracker: TrackerBase, 
		type: PuppeteerBase.Type,
		puppeteer_name: String) -> PuppeteerBase:
	var tracker_name: StringName = tracker.name if tracker else &""
	var new_puppeteer: PuppeteerBase = PuppeteerBase.create_new(type, tracker_name, puppeteer_name)
	if not new_puppeteer:
		return null
	
	if tracker:
		var reg_puppeteers = self._get_or_add_tracker(tracker)
		reg_puppeteers.append(new_puppeteer)
	
	self.add_child(new_puppeteer)
	new_puppeteer.owner = self
	
	# Insert at correct position
	self.update_puppeteer_order()
	
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
	var puppeteer_id: int = 0
	for tracker_puppeteers: Array[PuppeteerBase] in self._registered_trackers.values():
		for p in tracker_puppeteers:
			self.move_child(p, puppeteer_id)
			puppeteer_id += 1
	

func get_puppeteer_gui() -> GuiTabMenuBase:
	return self._puppeteer_gui_menu
