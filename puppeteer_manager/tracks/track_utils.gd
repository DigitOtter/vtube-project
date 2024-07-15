class_name TrackUtils

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

static func add_add_node(blend_tree: AnimationNodeBlendTree, node_name: StringName) -> StringName:
	var add_node := AnimationNodeAdd2.new()
	blend_tree.add_node(node_name, add_node)
	return node_name

static func add_anim_node(blend_tree: AnimationNodeBlendTree, 
						   node_name: StringName, track_name: StringName) -> StringName:
	var anim_node := AnimationNodeAnimation.new()
	anim_node.animation = track_name
	anim_node.play_mode = AnimationNodeAnimation.PLAY_MODE_FORWARD
	blend_tree.add_node(node_name, anim_node)
	return node_name

static func add_empty_anim_node(blend_tree: AnimationNodeBlendTree, node_name: StringName) -> StringName:
	var empty_node: AnimationRootNode = ANIMATION_NODE_EMPTY.duplicate()
	blend_tree.add_node(node_name, empty_node)
	return node_name

static func setup_animation_tree(blend_tree: AnimationNodeBlendTree, 
								 track_names: Array[String],
								 reset_track: StringName = &"") -> Dictionary:
	var track_blend_data := {}
	
	var base_node_name: StringName = &""
	if !reset_track.is_empty():
		base_node_name = add_anim_node(blend_tree, ANIMATION_NODE_PREFIX + reset_track, reset_track)
	else:
		base_node_name = add_empty_anim_node(blend_tree, &"EmptyStart")
	
	var add_node_name: StringName = &""
	var new_anim_node_name: StringName = &""
	
	# For each track, add and connect one animation_node with the "add" port of one add_node
	# The add_node is labelled track_name, and the animation_node gets ANIMATION_NODE_PREFIX + track_name
	for track_name in track_names:
		add_node_name = add_add_node(blend_tree, track_name)
		new_anim_node_name = add_anim_node(blend_tree, ANIMATION_NODE_PREFIX + track_name, track_name)
		
		blend_tree.connect_node(add_node_name, 0, base_node_name)
		blend_tree.connect_node(add_node_name, 1, new_anim_node_name)
		
		var blend_data := BlendData.new()
		blend_data.node = blend_tree.get_node(add_node_name)
		blend_data.param = &"parameters/" + add_node_name + &"/add_amount"
		track_blend_data[track_name] = blend_data
		
		base_node_name = add_node_name
	
	# Connect the last add node to the tree's output
	blend_tree.connect_node(&"output", 0, add_node_name)
	
	return track_blend_data
