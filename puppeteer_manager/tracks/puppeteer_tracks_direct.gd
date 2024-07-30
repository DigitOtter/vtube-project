## Apply tracks manually instead of using an [AvatarAnimationTree]. This puppeteer only supports pure
## blendshape tracks. Also, it's probably slower than [PuppeteerTrackTree], so use that one instead.
class_name PuppeteerTracksDirect
extends PuppeteerBase

class BlendShapeData:
	var mesh: MeshInstance3D
	var blend_shape_id: int

class Morph:
	## idx pointing to element in _blend_shape_mappings
	var idx: int = -1
	var value: float

class AnimationTrack:
	var morphs: Array[Morph]
	var target: float = 0.0
	var tracking_data:= TrackingData.new()

class TrackingData:
	var cur_val: float = 0.0
	var rate: float = 1.0

class TrackTarget:
	var name: StringName
	var target: float = 0.0

## Stored animation tracks. Elements should be of the form String: AnimationTrack
var _tracks: Dictionary = {}

## Stored blendshapes. This array enables quick modification of blendshape values
var _blend_shape_data: Array[BlendShapeData] = []

## Maps from track_name to element in _blend_shape_mappings.
## Elements should be of the form String: int
var _track_blend_shapes: Dictionary = {}

## Puppet's animation_player
var animation_player: AnimationPlayer = null

## Track that resets puppet back to its original shape
var reset_track: StringName = "RESET"

func _add_track(animations: AnimationPlayer, track_path: StringName) -> int:
	var split: PackedStringArray = track_path.split(":")
	if split.size() != 2:
		push_warning("Model has ultra nested meshes: %s" % track_path)
		return -1
	
	var mesh = animations.get_node_or_null('../' + split[0])
	if not mesh or not mesh is MeshInstance3D:
		push_warning("Unable to find mesh: %s" % split[0])
		return -1
	
	var blend_idx = mesh.find_blend_shape_by_name(split[1])
	if blend_idx == null:
		# Only save blend shape animation tracks
		return -1
	
	var blend_shape = BlendShapeData.new()
	blend_shape.mesh = mesh
	blend_shape.blend_shape_id = blend_idx
	
	var idx = self._blend_shape_data.size()
	self._blend_shape_data.append(blend_shape)
	self._track_blend_shapes[track_path] = idx
	
	return idx

func _reset_animation_to_track(animation_track: AnimationTrack):
	animation_track.tracking_data.cur_val = lerpf(animation_track.tracking_data.cur_val, 
												  animation_track.target, 
												  animation_track.tracking_data.rate)
	
	for morph: Morph in animation_track.morphs:
		var b: BlendShapeData  = self._blend_shape_data[morph.idx]
		b.mesh.set_blend_shape_value(b.blend_shape_id, animation_track.target * morph.value)

func _apply_animation_track(animation_track: AnimationTrack):
	animation_track.tracking_data.cur_val = lerpf(animation_track.tracking_data.cur_val, 
												  animation_track.target, 
												  animation_track.tracking_data.rate)
	
	for morph: Morph in animation_track.morphs:
		var b: BlendShapeData  = self._blend_shape_data[morph.idx]
		var val: float = b.mesh.get_blend_shape_value(b.blend_shape_id)
		val += animation_track.tracking_data.cur_val * morph.value
		b.mesh.set_blend_shape_value(b.blend_shape_id, val)

func initialize(anim_player: AnimationPlayer, reset_track_name: StringName = "RESET", ):
	self.animation_player = anim_player
	self.animation_player.speed_scale = 0.0
	
	# Set animation player to manual processing. This ensures that an avatar's animations are
	# only actively updates and not accidentally set after update_puppet was called
	self.animation_player.set_process_callback(AnimationPlayer.ANIMATION_PROCESS_MANUAL)
	
	self.reset_track = reset_track_name

func populate_tracks(animations: AnimationPlayer, animation_tracks: Array[String]):
	for track_name in animation_tracks:
		var animation = animations.get_animation(track_name)
		var split = track_name.split('/', true, 1)
		var vrm_name: String = split[split.size()-1] if split.size() > 0 else track_name
		vrm_name = vrm_name.to_lower()
		
		var morphs = self._tracks.get(vrm_name, null)
		if not morphs is Array:
			var animation_track := AnimationTrack.new()
			animation_track.morphs = []
			morphs = animation_track.morphs
			self._tracks[vrm_name] = animation_track
		
		var num_tracks := animation.get_track_count()
		for track_idx in range(0, num_tracks):
			var track_path: String = animation.track_get_path(track_idx)
			#var track_type := animation.track_get_type(track_idx)
			var blend_shape_idx = self._track_blend_shapes.get(track_path, -1)
			if blend_shape_idx == -1:
				blend_shape_idx = self._add_track(animations, track_path)
				if blend_shape_idx < 0:
					continue
			
			var morph := Morph.new()
			morph.idx = blend_shape_idx
			morph.value = animation.track_get_key_value(track_idx, 0)
			
			morphs.append(morph)
	
	self.adjust_tracking_to_target()

func set_track_targets(track_targets: Array[TrackTarget]) -> void:
	for t in track_targets:
		var animation_track = self._tracks.get(t.name)
		if animation_track:
			animation_track.target = t.target

## Takes targets as a dictionary. Elements should be of the form String -> float (track_name -> value)
func set_track_targets_dict(track_targets: Dictionary) -> void:
	# TODO: Use key-value pairs once https://github.com/godotengine/godot-proposals/issues/3457
	# is implemented
	for vmc_name: String in track_targets:
		var animation_track = self._tracks.get(vmc_name.to_lower())
		if animation_track:
			animation_track.target = track_targets[vmc_name]

func set_track_targets_mp(track_targets: Array[MediaPipeCategory]) -> void:
	for t in track_targets:
		var animation_track = self._tracks.get(t.category_name.to_lower())
		if animation_track:
			animation_track.target = t.score

func adjust_tracking_to_target():
	for t: AnimationTrack in self._tracks.values():
		t.tracking_data.cur_val = t.target

func update_puppet(_delta: float) -> void:
	# Reset all animations
	self.animation_player.current_animation = self.reset_track
	self.animation_player.seek(0, true)
	
	for t: AnimationTrack in self._tracks.values():
		self._apply_animation_track(t)
