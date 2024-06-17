class_name TrackerVmcReceiver
extends TrackerBase

const VMC_BONE_CONTROL: GDScript = preload("./scripts/VMCControl/VMCBoneControl.gd")
const VMC_BLEND_SHAPE_CONTROL: GDScript = preload("./scripts/VMCControl/VMCBlendShapeControl.gd")
const VMC_CAMERA_CONTROL: GDScript = preload("./scripts/VMCControl/VMCCameraControl.gd")

const GUI_TAB_NAME := &"Vmc Receiver"

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

func _on_port_input_changed(data: float):
	var new_port := roundi(data)
	if new_port > 0 and new_port < 65536:
		self.vmc_receiver.port = new_port
	
	# Ensure that port binding was successful
	if self.vmc_receiver.port != new_port:
		self.emit_signal(&"port_input_change", self.vmc_receiver.port, false)

func _init_gui():
	var trackers_node = get_node(Trackers.TRACKERS_NODE_PATH)
	var gui_elements: GuiElements = trackers_node.get_tracker_gui()
	var elements: Array[GuiElements.ElementData] = []
	
	var port_input := GuiElements.ElementData.new()
	port_input.Name = "Port Input"
	port_input.OnDataChangedCallable = self._on_port_input_changed
	port_input.SetDataSignal = [ self, &"port_input_change" ]
	port_input.Data = GuiElements.SliderData.new()
	(port_input.Data as GuiElements.SliderData).Default  = self.vmc_receiver.port
	(port_input.Data as GuiElements.SliderData).Step     = 1
	(port_input.Data as GuiElements.SliderData).MinValue = 1
	(port_input.Data as GuiElements.SliderData).MaxValue = 65535
	
	elements.append(port_input)
	
	gui_elements.add_or_create_elements_to_tab_name(GUI_TAB_NAME, elements)

func _on_avatar_loaded(avatar_scene: Node):
	self.restart_tracker(avatar_scene)

func _ready():
	if not self.is_ancestor_of(self.vmc_receiver):
		self.add_child(self.vmc_receiver)
		self.vmc_receiver.owner = self

func _process(delta):
	# Forward bone_poses to puppeteer
	# TODO: This is not thread-safe. In the future, should the VmcReceiver be altered to run in a
	# separate thread, duplicate bone_poses in the thread instead of using a reference here
	self.puppeteer_skeleton.bone_poses = self.vmc_receiver.bone_poses
	
	# Apply vmc rename
	# TODO: Use key-value pair once implemented
	var bs := self.vmc_receiver.blend_shapes
	for vmc_name in self.vmc_renames:
		var name = self.vmc_renames[vmc_name]
		bs[name] = bs.get(vmc_name, 0.0)
	self.puppeteer_tracks.set_track_targets_dict(self.vmc_receiver.blend_shapes)

func start_tracker(avatar_scene: Node) -> void:
	var puppeteer_manager = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH)
	if self.puppeteer_skeleton:
		puppeteer_manager.remove_puppeteer(self.puppeteer_skeleton)
	self.puppeteer_skeleton = \
		puppeteer_manager.request_new_puppeteer(self, PuppeteerBase.Type.SKELETON_DIRECT)
	
	if self.puppeteer_tracks:
		puppeteer_manager.remove_puppeteer(self.puppeteer_tracks)
	self.puppeteer_tracks = \
		puppeteer_manager.request_new_puppeteer(self, PuppeteerBase.Type.TRACK_TREE)
	
	# Setup skeleton puppeteer
	# TODO: What happens if there are multiple avatars?
	var avatar_root: Node = avatar_scene.get_child(0)
	var skeleton = avatar_scene.find_child("GeneralSkeleton")
	self.puppeteer_skeleton.initialize(skeleton, PuppeteerBase.get_vrm_bone_mappings(avatar_root))
	
	# Forward bone_poses to puppeteer
	# TODO: This is not thread-safe. In the future, should the VmcReceiver be altered to run in a
	# separate thread, duplicate bone_poses in the thread instead of using a reference here
	self.puppeteer_skeleton.bone_poses = self.vmc_receiver.bone_poses
	
	# Setup animation tracks puppeteer
	var animations = avatar_scene.find_child("AnimationPlayer")
	var animation_tracks: Array[String] = Array(Array(animations.get_animation_list()), TYPE_STRING, &"", null)
	animation_tracks.erase("RESET")
	self.puppeteer_tracks.initialize(animations, animation_tracks, &"RESET")
	
	self._init_gui()

func stop_tracker():
	var trackers_node = get_node(Trackers.TRACKERS_NODE_PATH)
	trackers_node.get_tracker_gui().remove_tab(GUI_TAB_NAME)
	
	super()
