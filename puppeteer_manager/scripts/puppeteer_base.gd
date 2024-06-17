class_name PuppeteerBase
extends Node

enum Type {
	SKELETON_DIRECT,
	SKELETON_IK,
	BLEND_SHAPES_DIRECT,
	TRACK_DIRECT,
	TRACK_TREE,
}

static func create_new(type: Type) -> PuppeteerBase:
	if type == Type.SKELETON_DIRECT:
		return PuppeteerSkeletonDirect.new()
	elif type == Type.SKELETON_IK:
		return PuppeteerSkeletonIk.new()
	elif type == Type.BLEND_SHAPES_DIRECT:
		return PuppeteerBlendShapesDirect.new()
	elif type == Type.TRACK_DIRECT:
		return PuppeteerTracksDirect.new()
	elif type == Type.TRACK_TREE:
		return PuppeteerTrackTree.new()
	
	return null

static func get_vrm_animation_player(avatar_root: Node) -> AnimationPlayer:
	return avatar_root.find_child("AnimationPlayer")

static func get_vrm_bone_mappings(avatar_root: Node) -> BoneMap:
	if avatar_root.get("vrm_meta"):
		return avatar_root.vrm_meta.humanoid_bone_mapping
	
	return null

func update_puppet(_delta: float) -> void:
	pass
