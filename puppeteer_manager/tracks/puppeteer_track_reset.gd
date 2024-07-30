## Resets all tracks to default
class_name PuppeteerTrackReset
extends PuppeteerBase

var _blend_tree := AnimationNodeBlendTree.new()

func _ready():
	self.add_child(self.animation_tree)
	self.animation_tree.owner = self
	
	super()

## Initialize the animation_tree. If reset_track is set, this puppeteer will reset the puppet
## before applying any other blend_tracks.
func initialize(animation_tree: AvatarAnimationTree, reset_track: StringName = &"RESET"):
	self._blend_tree = AnimationNodeBlendTree.new()
	var reset_anim := animation_tree.create_animation_node(reset_track) \
						if !reset_track.is_empty() else null
	self._blend_nodes = AvatarTrackUtils.setup_animation_tree(self._blend_tree, [], reset_anim)
	
	var node_name = self.name
	AvatarTrackUtils.adjust_blend_data_param_to_subtree(self._blend_nodes, node_name)
	animation_tree.push_node(node_name, self._blend_tree)

func update_puppet(_delta: float) -> void:
	## AnimationTree resets the tracks automatically, no need to do anything here
	pass
