class_name AvatarBase
extends Node3D

const ANIMATION_TREE_NODE_NAME := &"AnimationTree"
const VRM_META_CLASS: GDScript = preload("res://addons/vrm/vrm_meta.gd")

## VRM Avatar root. Should be child of this node
var _vrm_root_node: VRMTopLevel = null

static func create_new() -> AvatarBase:
	return preload("./avatar_base.tscn").instantiate()

## Set VRM Avatar root. Should be child of this node
func set_vrm_avatar(vrm_root: VRMTopLevel):
	self._vrm_root_node = vrm_root
	self.add_child(vrm_root)
	vrm_root.owner = self

func get_vrm_meta() -> VRM_META_CLASS:
	return self._vrm_root_node.get(&"vrm_meta")

func get_avatar_root() -> VRMTopLevel:
	return self._vrm_root_node

## Returns the avatar's animation player if available
func get_animation_player() -> AnimationPlayer:
	return self._vrm_root_node.find_child("AnimationPlayer", true)

## Returns the avatar's animation tree, creates it if missing. If avatar has no AnimationPlayer, return null
func get_animation_tree() -> AvatarAnimationTree:
	var animation_player := self.get_animation_player()
	if not animation_player:
		return null
	
	var animation_tree: AnimationTree = animation_player.find_child(ANIMATION_TREE_NODE_NAME, false)
	if not animation_tree:
		animation_tree = AnimationTree.new()
		animation_player.add_child(animation_tree)
		animation_tree.owner = animation_player
		animation_tree.name = ANIMATION_TREE_NODE_NAME
		
		animation_tree.anim_player = animation_player.get_path()
	
	return animation_tree

func get_skeleton() -> Skeleton3D:
	return self._vrm_root_node.find_child("GeneralSkeleton")
