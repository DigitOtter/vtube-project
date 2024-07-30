class_name TrackerVmcReceiver
extends TrackerBase

const GUI_TAB_NAME := &"Vmc Receiver"
const TRACKER_NAME := &"VmcReceiver"

signal port_input_change(data: float, propagate: bool)

var vmc_renames: Dictionary = {
	&"A": &"aa",
	&"E": &"ee",
	&"I": &"ih",
	&"O": &"oh",
	&"U": &"ou",
}

@export 
var vmc_receiver: VmcReceiver = VmcReceiver.new()

var puppeteer_skeleton: PuppeteerSkeletonDirect = null
var puppeteer_tracks: PuppeteerTrackTree = null

static func get_type_name() -> StringName:
	return &"VmcReceiver"

func _on_port_input_changed(data: float):
	var new_port := roundi(data)
	if new_port > 0 and new_port < 65536:
		self.vmc_receiver.port = new_port
	
	# Ensure that port binding was successful
	if self.vmc_receiver.port != new_port:
		self.emit_signal(&"port_input_change", self.vmc_receiver.port, false)

func _on_avatar_loaded(avatar_base: AvatarBase):
	self.restart_tracker(avatar_base)

func _ready():
	# Only start processing after tracker was started
	self.set_process(false)
	
	if not self.is_ancestor_of(self.vmc_receiver):
		self.add_child(self.vmc_receiver)
		self.vmc_receiver.owner = self
	
	super()

func _process(_delta):
	# Forward bone_poses to puppeteer
	# TODO: This is not thread-safe. In the future, should the VmcReceiver be altered to run in a
	# separate thread, duplicate bone_poses in the thread instead of using a reference here
	self.puppeteer_skeleton.bone_poses = self.vmc_receiver.bone_poses
	
	# Apply vmc rename
	# TODO: Use key-value pair once implemented
	var bs := self.vmc_receiver.blend_shapes
	for vmc_name in self.vmc_renames:
		var new_name = self.vmc_renames[vmc_name]
		bs[new_name] = bs.get(vmc_name, 0.0)
	self.puppeteer_tracks.set_track_targets_dict(self.vmc_receiver.blend_shapes)

func add_gui():
	var trackers_node = get_node(TrackerManager.TRACKER_MANAGER_NODE_PATH)
	var gui_menu: GuiTabMenuBase = trackers_node.get_tracker_gui()
	var elements: Array[GuiElement.ElementData] = []
	
	var port_input := GuiElement.ElementData.new()
	port_input.Name = "Port Input"
	port_input.OnDataChangedCallable = self._on_port_input_changed
	port_input.SetDataSignal = [ self, &"port_input_change" ]
	port_input.Data = GuiElement.SliderData.new()
	(port_input.Data as GuiElement.SliderData).Default  = self.vmc_receiver.port
	(port_input.Data as GuiElement.SliderData).Step     = 1
	(port_input.Data as GuiElement.SliderData).MinValue = 1
	(port_input.Data as GuiElement.SliderData).MaxValue = 65535
	elements.append(port_input)
	
	gui_menu.add_elements_to_tab(GUI_TAB_NAME, elements)

func remove_gui():
	var trackers_node = get_node(TrackerManager.TRACKER_MANAGER_NODE_PATH)
	var gui_menu: GuiTabMenuBase = trackers_node.get_tracker_gui()
	gui_menu.remove_tab(GUI_TAB_NAME)

func start_tracker(avatar_base: AvatarBase) -> void:
	var puppeteer_manager = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH)
	if self.puppeteer_skeleton:
		puppeteer_manager.remove_puppeteer(self.puppeteer_skeleton)
	self.puppeteer_skeleton = \
		puppeteer_manager.request_new_puppeteer(self, PuppeteerBase.Type.SKELETON_DIRECT, "skel")
	
	if self.puppeteer_tracks:
		puppeteer_manager.remove_puppeteer(self.puppeteer_tracks)
	self.puppeteer_tracks = \
		puppeteer_manager.request_new_puppeteer(self, PuppeteerBase.Type.TRACK_TREE, "blend_shapes")
	
	# Setup skeleton puppeteer
	# TODO: What happens if there are multiple avatars?
	var skeleton = avatar_base.get_skeleton()
	self.puppeteer_skeleton.initialize(skeleton, PuppeteerBase.get_vrm_bone_mappings(avatar_base))
	
	# Forward bone_poses to puppeteer
	# TODO: This is not thread-safe. In the future, should the VmcReceiver be altered to run in a
	# separate thread, duplicate bone_poses in the thread instead of using a reference here
	self.puppeteer_skeleton.bone_poses = self.vmc_receiver.bone_poses
	
	# Setup animation tracks puppeteer
	var anim_player := avatar_base.get_animation_player()
	var anim_tree := avatar_base.get_animation_tree()
	var animation_tracks: Array[String] = Array(Array(anim_player.get_animation_list()), TYPE_STRING, &"", null)
	animation_tracks.erase("RESET")
	self.puppeteer_tracks.initialize(anim_tree, animation_tracks, &"RESET")
	
	self.set_process(true)
	
	super(avatar_base)

func stop_tracker():
	self.set_process(false)
	
	var trackers_node = get_node(TrackerManager.TRACKER_MANAGER_NODE_PATH)
	trackers_node.get_tracker_gui().remove_tab(GUI_TAB_NAME)
	
	super()
