class_name CccdIk
extends Node

class SpineChain:
	var bone_chain: Array[int] = []

class LimbChain:
	var bone_chain: Array[int] = []
	var joint_offset: float = 0

@export var target_head: Node3D = null
@export var target_hip: Node3D = null
#@export var target_left_hand:  Node3D = null
#@export var target_right_hand: Node3D = null
#@export var target_left_foot:  Node3D = null
#@export var target_right_foot: Node3D = null

@export var skeleton: Skeleton3D = null

var _spine_chain := SpineChain.new()

static func _find_chain(skeleton: Skeleton3D, root_bone: int, leaf_bone: int) -> Array[int]:
	# Recursively iterate over children until leaf_bone is found
	var bone_chain: Array[int] = []
	var child_bones := skeleton.get_bone_children(root_bone)
	for bone_idx: int in child_bones:
		if bone_idx == leaf_bone:
			bone_chain = [ leaf_bone ] as Array[int]
		else:
			bone_chain = CccdIk._find_chain(skeleton, bone_idx, leaf_bone)
		
		# If leaf bone was found, add this bone_idx and stop searching
		if not bone_chain.is_empty():
			bone_chain.push_front(root_bone)
			break
	
	return bone_chain

func init_skeleton_bones(head_bone: String, hip_bone: String):
	if not self.skeleton:
		return
	
	var head_idx: int = self.skeleton.find_bone(head_bone)
	var hip_idx: int = self.skeleton.find_bone(hip_bone)
	if head_idx < 0 or hip_idx < 0:
		return
	
	var spine_chain := self._find_chain(self.skeleton, hip_idx, head_idx)
	if spine_chain.is_empty():
		return
	
	self._spine_chain.bone_chain = spine_chain

func _perform_ccd_ik(bone_chain: Array[int], root_pose_node: Node3D, leaf_pose_node: Node3D):
	var bone_count: int = bone_chain.size()
	if bone_count < 2:
		return
	
	var inv_skeleton_tx := self.skeleton.global_transform.inverse()
	var root_pose := inv_skeleton_tx * root_pose_node.global_transform
	var leaf_pose := inv_skeleton_tx * leaf_pose_node.global_transform
	
	# Reset bone poses
	for id: int in range(0, bone_count):
		self.skeleton.reset_bone_pose(bone_chain[id])
	
	# Set leaf orientation
	#self.skeleton.set_bone_pose_rotation(bone_chain.back(), leaf_pose_node.basis)
	var rotation := self.skeleton.get_bone_global_pose(bone_chain.back()).basis
	
	# Go through chain in reverse
	for id in range(bone_count-2, 0, -1):
		var cur_bone_idx := bone_chain[id]
		
		var leaf_bone_pose := self.skeleton.get_bone_global_pose(bone_chain.back())
		var cur_bone_pose := self.skeleton.get_bone_global_pose(cur_bone_idx)
		var leaf_normal: Vector3 =  (leaf_bone_pose.origin - cur_bone_pose.origin).normalized()
		var target_normal: Vector3 =  (leaf_pose.origin - cur_bone_pose.origin).normalized()
		
		var rot_axis: Vector3 = leaf_normal.cross(target_normal)
		var rot_angle: float = leaf_normal.dot(target_normal)
		var target_global_rot := Quaternion(rot_axis, rot_angle)
		if not target_global_rot.is_finite():
			continue
		
		var prev_rot: Quaternion = self.skeleton.get_bone_global_pose(cur_bone_idx-1) if cur_bone_idx > 0 else Quaternion.IDENTITY
		var target_local_rot: Quaternion = target_global_rot * prev_rot.inverse()
		self.skeleton.set_bone_pose_rotation(cur_bone_idx, target_local_rot)
