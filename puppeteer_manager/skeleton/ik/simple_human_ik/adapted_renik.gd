@tool
class_name AdaptedRenik
extends RenIK3D

var move_arms_to_a_pose: bool = true

var _simple_human_ik := preload("./simple_human_ik.gd").new()

# Called when the node enters the scene tree for the first time.
func _ready():
	if self.get_child_count() == 0:
		self.add_child(self._simple_human_ik)
		self._simple_human_ik.owner = self
	
	super()
	self.update_skeleton()

func update_skeleton():
	super()
	self._simple_human_ik.skeleton = self.skeleton
	
	self._simple_human_ik.target_head = get_node_or_null(self.armature_head_target)
	self._simple_human_ik.target_hip = get_node_or_null(self.armature_hip_target)
	
	self._simple_human_ik.head_bone_name = self.armature_head
	self._simple_human_ik.hip_bone_name = self.armature_hip
	
	self._simple_human_ik.setup_ik()

func update_ik() -> void:
	if not skeleton:
		return
	var skel_inverse: Transform3D = skeleton.global_transform.affine_inverse()
	var spine_global_transforms: SpineGlobalTransforms = SpineGlobalTransforms.new()
	self._simple_human_ik.update_ik()
	
	if self.move_arms_to_a_pose:
		if hand_left_target_spatial:
			perform_hand_left_ik(spine_global_transforms.leftArmParentTransform, skel_inverse * hand_left_target_spatial.global_transform)

		if hand_right_target_spatial:
			perform_hand_right_ik(spine_global_transforms.rightArmParentTransform, skel_inverse * hand_right_target_spatial.global_transform)

	# TODO: Fix foot placement
	#if foot_left_target_spatial:
	#	perform_foot_left_ik(spine_global_transforms.hipTransform, skel_inverse * foot_left_target_spatial.global_transform)

	#if foot_right_target_spatial:
	#	perform_foot_right_ik(spine_global_transforms.hipTransform, skel_inverse * foot_right_target_spatial.global_transform)
