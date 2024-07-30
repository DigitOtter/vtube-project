class_name AvatarTrackUtils

class TrackTarget:
	var name: StringName
	var target: float = 0.0

class BlendData:
	var node: AnimationNodeAdd2 = null
	var param: StringName
	var rate: float = 0.1 * 60
	var target: float = 0.0

const ANIMATION_NODE_PREFIX := &"Animation_"
const ANIMATION_NODE_EMPTY = preload("./animation_node_empty.tres")

static func _add_add_node(blend_tree: AnimationNodeBlendTree, node_name: StringName) -> StringName:
	var add_node := AnimationNodeAdd2.new()
	blend_tree.add_node(node_name, add_node)
	return node_name

static func _add_anim_node(blend_tree: AnimationNodeBlendTree, 
						  node_name: StringName, animation: AnimationNodeAnimation) -> StringName:
	animation.play_mode = AnimationNodeAnimation.PLAY_MODE_FORWARD
	blend_tree.add_node(node_name, animation)
	return node_name

static func _add_empty_anim_node(blend_tree: AnimationNodeBlendTree, node_name: StringName) -> StringName:
	var empty_node: AnimationRootNode = ANIMATION_NODE_EMPTY.duplicate()
	blend_tree.add_node(node_name, empty_node)
	return node_name

## Adds animations to blend_tree. Each animation is connected to a AnimationNodeAdd2 node.
## For each AnimationNodeAnimation in animations, the returned dictionary has an entry
## { animation.anim: BlendData }.
static func setup_animation_tree(blend_tree: AnimationNodeBlendTree, 
								 animations: Array[AnimationNodeAnimation],
								 reset_animation: AnimationNodeAnimation) -> Dictionary:
	var track_blend_data := {}
	
	var base_node_name: StringName = &""
	if reset_animation:
		base_node_name = AvatarTrackUtils._add_anim_node(
			blend_tree, 
			ANIMATION_NODE_PREFIX + reset_animation.animation, 
			reset_animation)
	else:
		base_node_name = AvatarTrackUtils._add_empty_anim_node(blend_tree, &"EmptyStart")
	
	var add_node_name: StringName = base_node_name
	var new_anim_node_name: StringName = &""
	
	# For each track, add and connect one animation_node with the "add" port of one add_node
	# The add_node is labelled track_name, and the animation_node gets ANIMATION_NODE_PREFIX + track_name
	for anim in animations:
		add_node_name = AvatarTrackUtils._add_add_node(blend_tree, anim.animation)
		new_anim_node_name = AvatarTrackUtils._add_anim_node(blend_tree, ANIMATION_NODE_PREFIX + anim.animation, anim)
		
		blend_tree.connect_node(add_node_name, 0, base_node_name)
		blend_tree.connect_node(add_node_name, 1, new_anim_node_name)
		
		var blend_data := BlendData.new()
		blend_data.node = blend_tree.get_node(add_node_name)
		blend_data.param = &"parameters/" + add_node_name + &"/add_amount"
		track_blend_data[anim.animation] = blend_data
		
		base_node_name = add_node_name
	
	# Connect the last add node to the tree's output
	blend_tree.connect_node(&"output", 0, add_node_name)
	
	return track_blend_data
