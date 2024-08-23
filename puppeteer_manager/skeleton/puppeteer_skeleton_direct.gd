class_name PuppeteerSkeletonDirect
extends    PuppeteerBase

class BoneData:
	var tf: Transform3D = Transform3D.IDENTITY
	var lerp_rate: float = 1.0
	var enable_bone: bool = true

var skeleton: Skeleton3D

## Store target bone poses. Should be of the form { bone_idx: local_bone_tf }
var _bone_poses: Dictionary = {}

func initialize(puppet_skeleton: Skeleton3D, _bone_mapping: BoneMap):
	self.skeleton = puppet_skeleton

func delete_bone(bone_idx) -> void:
	self._bone_poses.erase(bone_idx)

func set_bone_enable(bone_idx: int, bone_enable: bool) -> void:
	var bone_data: BoneData = self._bone_poses.get(bone_idx, null)
	if not bone_data:
		bone_data = BoneData.new()
		self._bone_poses[bone_idx] = bone_data
	
	bone_data.enabled = bone_enable

func set_bone_lerp_rate(bone_idx: int, bone_lerp_rate: float) -> void:
	var bone_data: BoneData = self._bone_poses.get(bone_idx, null)
	if not bone_data:
		bone_data = BoneData.new()
		self._bone_poses[bone_idx] = bone_data
	
	bone_data.lerp_rate = bone_lerp_rate

func set_bone_tf(bone_idx: int, bone_tf: Transform3D) -> void:
	var bone_data: BoneData = self._bone_poses.get(bone_idx, null)
	if not bone_data:
		bone_data = BoneData.new()
		self._bone_poses[bone_idx] = bone_data
	
	bone_data.tf = bone_tf

func update_puppet(delta: float):
	for bone_idx: int in self._bone_poses.keys():
		var bone_data: BoneData = self._bone_poses[bone_idx]
		var bone_tf: Transform3D = self.skeleton.get_bone_pose(bone_idx)
		bone_tf = bone_tf.interpolate_with(bone_data.tf, bone_data.lerp_rate * delta)
		self.skeleton.set_bone_pose_position(bone_idx, bone_tf.origin)
		self.skeleton.set_bone_pose_rotation(bone_idx, bone_tf.basis)
