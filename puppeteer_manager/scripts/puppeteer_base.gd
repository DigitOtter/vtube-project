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
		puppeteer = preload("../skeleton/puppeteer_skeleton_ik.tscn").instantiate()
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

static func get_vrm_animation_player(avatar_root: Node) -> AnimationPlayer:
	return avatar_root.find_child("AnimationPlayer")

static func get_vrm_bone_mappings(avatar_root: Node) -> BoneMap:
	if avatar_root.get("vrm_meta"):
		return avatar_root.vrm_meta.humanoid_bone_mapping
	
	return null

func _ready():
	# Add GUI on creation, remove on deletion
	self.add_gui()
	self.connect(&"tree_exiting", self.remove_gui)

func add_gui():
	pass

func remove_gui():
	pass

func update_puppet(_delta: float) -> void:
	pass
