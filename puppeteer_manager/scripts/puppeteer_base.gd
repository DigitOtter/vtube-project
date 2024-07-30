class_name PuppeteerBase
extends Node

enum Type {
	SKELETON_DIRECT,
	SKELETON_IK,
	BLEND_SHAPES_DIRECT,
	TRACK_RESET,
	TRACK_DIRECT,
	TRACK_TREE,
	TRACK_EMOTION,
}

static func _gen_name(tracker_name: String, puppeteer_name: String) -> String:
	if !tracker_name.is_empty():
		return "%s:%s" % [ tracker_name, puppeteer_name ]
	else:
		return puppeteer_name

static func create_new(type: Type, tracker_name: String, puppeteer_name: String) -> PuppeteerBase:
	var puppeteer: PuppeteerBase = null
	if type == Type.SKELETON_DIRECT:
		puppeteer = PuppeteerSkeletonDirect.new()
	elif type == Type.SKELETON_IK:
		puppeteer = PuppeteerSkeletonIk.new()
	elif type == Type.BLEND_SHAPES_DIRECT:
		puppeteer = PuppeteerBlendShapesDirect.new()
	elif type == Type.TRACK_RESET:
		puppeteer = PuppeteerTrackReset.new()
	elif type == Type.TRACK_DIRECT:
		puppeteer = PuppeteerTracksDirect.new()
	elif type == Type.TRACK_TREE:
		puppeteer = PuppeteerTrackTree.new()
	elif type == Type.TRACK_EMOTION:
		puppeteer = PuppeteerTrackEmotion.new()
	
	if puppeteer:
		puppeteer.name = PuppeteerBase._gen_name(tracker_name, puppeteer_name)
	
	return puppeteer

static func get_vrm_animation_player(avatar_base: AvatarBase) -> AnimationPlayer:
	return avatar_base.get_animation_player()

static func get_vrm_bone_mappings(avatar_base: AvatarBase) -> BoneMap:
	var vrm_meta := avatar_base.get_vrm_meta()
	return vrm_meta.humanoid_bone_mapping if vrm_meta else null

func _ready():
	# Add GUI on creation, remove on deletion
	self.add_gui()
	self.connect(&"tree_exiting", self.remove_gui)

## Override if the puppeteer uses an AnimationNode in the avatar's AnimationTree. The
## PuppeteerManager uses this to keep the AnimationTree's order consistent with puppeteer order.
func get_animation_node_name() -> String:
	return ""

func add_gui():
	pass

func remove_gui():
	pass

func update_puppet(_delta: float) -> void:
	pass
