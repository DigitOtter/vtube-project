class_name AvatarAnimationTree
extends AnimationTree

const RESET_TRACK_NAME := &"RESET"
const BASE_ANIM_NODE_NAME := &"ResetNode"
const ADD_ANIM_NODE_PREFIX := &"AddNode"
const ANIMATION_NODE_EMPTY := preload("./animation_node_empty.tres")

var _base_node: AnimationRootNode = null
var _base_blend_data: Dictionary = {}

## Manually keep track of animation nodes. Each node in the array is connected to the add 
## port of the corresponding add_node_<id>
## TODO: Post Godot feature request for looking up connections between nodes
var _sub_animations: Array[StringName] = []

static func create_new() -> AvatarAnimationTree:
	return preload("./avatar_animation_tree.tscn").instantiate()

static func _get_add_node_name(id: int) -> StringName:
	return ADD_ANIM_NODE_PREFIX + String.num(id)

static func _create_animation_node(track_name: StringName) -> AnimationNodeAnimation:
	var animation := AnimationNodeAnimation.new()
	animation.animation = track_name
	return animation

func _set_base_input_node(animation_node: AnimationRootNode):
	if self.tree_root.has_node(BASE_ANIM_NODE_NAME):
		self.tree_root.remove_node(BASE_ANIM_NODE_NAME)
	self.tree_root.add_node(BASE_ANIM_NODE_NAME, animation_node)
	
	var out_node := AvatarAnimationTree._get_add_node_name(0) if not self._sub_animations.is_empty() else &"output"
	self.tree_root.connect_node(out_node, 0, BASE_ANIM_NODE_NAME)
	
	self._base_node = animation_node

func _set_add_node_amount(add_id: int, amount: float):
	var add_node := AvatarAnimationTree._get_add_node_name(add_id)
	self.set(&"parameters/" + add_node + &"/add_amount", amount)

func _replace_or_add_sub_animation(anim_name: StringName, animation: AnimationRootNode):
	var anim_id: int = -1
	for id: int in range(0, self._sub_animations.size()):
		if self._sub_animations[id] == anim_name:
			anim_id = id
			break
	
	if anim_id < 0:
		return self._add_sub_animation(anim_name, animation)
	
	self.tree_root.remove_node(self._sub_animations[anim_id])
	self.tree_root.add_node(anim_name, animation)
	self.tree_root.connect_node(AvatarAnimationTree._get_add_node_name(anim_id), 1, anim_name)
	self._sub_animations[anim_id] = anim_name

func _add_sub_animation(anim_name: StringName, animation: AnimationRootNode):
	# Create new AnimationNode2Add and connect animation to add port
	var new_add_node := AvatarAnimationTree._get_add_node_name(self._sub_animations.size())
	self.tree_root.add_node(anim_name, animation)
	self.tree_root.add_node(new_add_node, AnimationNodeAdd2.new())
	self.tree_root.connect_node(new_add_node, 1, anim_name)
	
	# Insert add node at end of tree
	var prev_last_add_node := AvatarAnimationTree._get_add_node_name(self._sub_animations.size()-1) \
								if self._sub_animations.size() > 0 else BASE_ANIM_NODE_NAME
	self.tree_root.disconnect_node(&"output", 0)
	self.tree_root.connect_node(&"output", 0, new_add_node)
	self.tree_root.connect_node(new_add_node, 0, prev_last_add_node)
	
	# Save name of stored animation
	self._set_add_node_amount(self._sub_animations.size(), 1.0)
	self._sub_animations.push_back(anim_name)

func _find_sub_animation_id(anim_name: StringName) -> int:
	for id: int in range(0, self._sub_animations.size()):
		if self._sub_animations[id] == anim_name:
			return id
	return -1

func _swap_sub_animations(anim_1: StringName, anim_2: StringName):
	var anim_1_id: int = self._find_sub_animation_id(anim_1)
	var anim_2_id: int = self._find_sub_animation_id(anim_2)
	if anim_1_id < 0 or anim_2_id < 0:
		return
	
	var add_node_1 := AvatarAnimationTree._get_add_node_name(anim_1_id)
	var add_node_2 := AvatarAnimationTree._get_add_node_name(anim_2_id)
	
	self.tree_root.disconnect_node(add_node_1, 1)
	self.tree_root.disconnect_node(add_node_2, 1)
	
	self.tree_root.connect_node(add_node_1, 1, anim_2_id)
	self.tree_root.connect_node(add_node_2, 1, anim_1_id)
	
	self._sub_animations[anim_1_id] = anim_2
	self._sub_animations[anim_2_id] = anim_1

func _remove_sub_animation(anim: StringName):
	var anim_id: int = self._find_sub_animation_id(anim)
	if anim_id < 0:
		return
	
	# Remove both add_node and anim_node
	var add_node := AvatarAnimationTree._get_add_node_name(anim_id)
	self.tree_root.remove_node(anim_id)
	self.tree_root.remove_node(add_node)
	
	# Rename add nodes to align them with id values
	for id: int in range(anim_id+1, self._sub_animations.size()):
		var old_add_node_name := AvatarAnimationTree._get_add_node_name(id)
		var new_add_node_name := AvatarAnimationTree._get_add_node_name(id-1)
		self.tree_root.rename_node(old_add_node_name, new_add_node_name)
	self._sub_animations.remove_at(anim_id)
	
	# Reconnect nodes
	var input_node = AvatarAnimationTree._get_add_node_name(anim_id-1) \
		if anim_id > 0 else BASE_ANIM_NODE_NAME
	self.tree_root.connect_node(add_node, 0, input_node)
	
	var output_node = AvatarAnimationTree._get_add_node_name(anim_id+1) \
		if anim_id < self._sub_animations.size()-1 else &"output"
	self.tree_root.connect_node(output_node, 0, add_node)

func _ready():
	self.reset_blend_tree()

### Workaround. Setting add nodes immediately after creating them currently results in an error.
### Right now we're activating them every process cycle
#func _process(_delta):
	#for id: int in range(0, self._sub_animations.size()):
		#self._set_add_node_amount(id, 1.0)

func reset_blend_tree(reset_track: StringName = RESET_TRACK_NAME):
	var blend_tree := AnimationNodeBlendTree.new()
	self.tree_root = blend_tree
	self._sub_animations = []
	
	self._set_base_input_node(AnimationRootNode.new())

func set_avatar_animation_player(avatar_base: AvatarBase):
	var p_anim_player := avatar_base.get_animation_player()
	self.anim_player = p_anim_player.get_path()
	self.root_node = avatar_base.get_avatar_root().get_path()

func initialize_clamped_animations(anim_names: Array[StringName], reset_name: StringName):
	var animations: Array[AnimationNodeAnimation] = []
	for anim_name in anim_names:
		animations.push_back(AvatarAnimationTree._create_animation_node(anim_name))
	var reset_anim := AvatarAnimationTree._create_animation_node(reset_name) if !reset_name.is_empty() \
						else null
	
	var blend_tree := AnimationNodeBlendTree.new()
	var blend_data := AvatarTrackUtils.setup_animation_tree(blend_tree, animations, reset_anim)
	
	self._set_base_input_node(blend_tree)
	self._base_blend_data = blend_data

func add_or_replace_node(node_name: StringName, node: AnimationRootNode):
	self._replace_or_add_sub_animation(node_name, node)

func create_animation_node(track: StringName) -> AnimationNodeAnimation:
	return AvatarAnimationTree._create_animation_node(track)

## Creates a clamped animation node. The new node shares it's weights with other
## AnimationNodeAnimationClamp that target the same track and that were created here.
#func create_animation_node_clamped(track: StringName, clamp_min: float = -INF, 
								   #clamp_max: float = INF) -> AnimationNodeAnimationClamp:
	#var animation_track := AnimationNodeAnimationClamp.new()
	#
	#var clamp_val: AnimationSharedWeight = self._clamped_animation_weights.get(track, null)
	#if not clamp_val:
		#clamp_val = AnimationSharedWeight.new()
		#self._clamped_animation_weights[track] = clamp_val
	#
	#clamp_val.clamp_min = clamp_min
	#clamp_val.clamp_max = clamp_max
	#
	#animation_track.shared_weight = clamp_val
	#animation_track.animation = track
	#return animation_track
