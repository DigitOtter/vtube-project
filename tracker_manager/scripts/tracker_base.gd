class_name TrackerBase
extends Node

enum Type {
	EMPTY,
	MEDIA_PIPE,
	VMC_RECEIVER,
}

static func _get_tracker_class(type: Type):
	if type == Type.EMPTY:
		return TrackerEmpty
	elif type == Type.MEDIA_PIPE:
		return TrackerMediaPipe
	elif type == Type.VMC_RECEIVER:
		return TrackerVmcReceiver
	
	return null

static func get_tracker_name(type: Type) -> StringName:
	var ctype = TrackerBase._get_tracker_class(type)
	if ctype:
		return ctype.TRACKER_NAME
	
	return &""

static func create_new(type: Type) -> TrackerBase:
	var tracker_class = TrackerBase._get_tracker_class(type)
	var tracker: TrackerBase = tracker_class.new() if tracker_class != null else null
	
	if tracker:
		tracker.name = TrackerBase.get_tracker_name(type)
	
	return tracker

func _on_tree_exiting():
	self.stop_tracker()

func _ready():
	self.connect(&"tree_exiting", self._on_tree_exiting)

func add_gui():
	pass

func remove_gui():
	pass

## Start tracker if an avatar is loaded
func init_tracker() -> void:
	# TODO: For now, we're only loading one avatar, but future use should select the correct avatar
	var main_node: Main = get_node_or_null(Main.MAIN_NODE_PATH)
	if main_node and main_node.is_avatar_loaded():
		self.start_tracker(main_node.get_avatar_root_node().get_avatars()[0])

func start_tracker(_avatar_base: AvatarBase) -> void:
	self.add_gui()

func stop_tracker():
	# On stop, remove all puppeteers that are linked to this tracker
	var puppeteer_manager = get_node(PuppeteerManager.PUPPETEER_MANAGER_NODE_PATH)
	puppeteer_manager.remove_tracker_puppeteers(self)
	
	self.remove_gui()

func restart_tracker(avatar_base: AvatarBase) -> void:
	self.stop_tracker()
	self.start_tracker(avatar_base)
