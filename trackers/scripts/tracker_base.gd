class_name  TrackerBase
extends Node

enum Type {
	MEDIA_PIPE,
	VMC_RECEIVER,
}

static func create_new(type: Type) -> TrackerBase:
	if type == Type.MEDIA_PIPE:
		# TODO
		return null
	elif type == Type.VMC_RECEIVER:
		return TrackerVmcReceiver.new()
	
	return null

func _on_tree_exiting():
	self.stop_tracker()

func _ready():
	self.connect(&"tree_exiting", self._on_tree_exiting)

func add_gui():
	pass

func remove_gui():
	pass

## Connect tracker to avatar_loaded. On load, the tracker is automatically
## reconfigured to target the new avatar.
func init_tracker() -> void:
	var main_node: Main = get_node_or_null(Main.MAIN_NODE_PATH)
	if main_node and main_node.is_avatar_loaded():
		self.start_tracker(main_node.get_avatar_root_node())
	
	print("NOTE: Uncomment VmcReceiver connect_signal if you want to load an avatar other than digit")
	get_node(Main.MAIN_NODE_PATH).connect_avatar_loaded(self.restart_tracker)

func start_tracker(avatar_scene: Node) -> void:
	pass

func stop_tracker():
	# On stop, remove all puppeteers that are linked to this tracker
	var puppeteer_manager = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH)
	puppeteer_manager.remove_tracker_puppeteers(self)

func restart_tracker(avatar_scene: Node) -> void:
	self.stop_tracker()
	self.start_tracker(avatar_scene)
