## Resets all tracks to default
class_name PuppeteerTrackReset
extends PuppeteerBase

var animation_tree:= AnimationTree.new()

func _ready():
	self.add_child(self.animation_tree)
	self.animation_tree.owner = self
	
	super()

## Initialize the animation_tree. If reset_track is set, this puppeteer will reset the puppet
## before applying any other blend_tracks.
func initialize(animations: AnimationPlayer, reset_track: StringName = &"RESET"):
	self.animation_tree.anim_player = animations.get_path()
	
	var blend_tree = AnimationNodeBlendTree.new()
	self._blend_nodes = TrackUtils.setup_animation_tree(blend_tree, [], reset_track)
	
	self.animation_tree.tree_root = blend_tree

func update_puppet(_delta: float) -> void:
	## AnimationTree resets the tracks automatically, no need to do anything here
	pass
