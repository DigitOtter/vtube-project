class_name PuppeteerSkeletonIk
extends    PuppeteerBase

class IkTargetBoneNames:
	var head: StringName            = &"Head"
	var hip: StringName             = &"Hips"
	var left_hand: StringName       = &"LeftHand"
	var left_lower_arm: StringName  = &"LeftLowerArm"
	var left_upper_arm: StringName  = &"LeftUpperArm"
	var right_hand: StringName      = &"RightHand"
	var right_lower_arm: StringName = &"RightLowerArm"
	var right_upper_arm: StringName = &"RightUpperArm"
	var left_foot: StringName       = &"LeftFoot"
	var left_lower_leg: StringName  = &"LeftLowerLeg"
	var left_upper_leg: StringName  = &"LeftUpperLeg"
	var right_foot: StringName      = &"RightFoot"
	var right_lower_leg: StringName = &"RightLowerLeg"
	var right_upper_leg: StringName = &"RightUpperLeg"

enum IkTarget {
	HEAD,
	HIP,
	LEFT_HAND,
	RIGHT_HAND,
	LEFT_FOOT,
	RIGHT_FOOT
}

const IK_TARGETS_NODE_PARENT_NAME: StringName = &"IkTargets"

var ik_targets_parent: Node3D = null

## All ik targets
@export_category(&"Targets")
@export var head_target:       LerpNode3D = LerpNode3D.new()
@export var hip_target:        LerpNode3D = LerpNode3D.new()
@export var left_hand_target:  LerpNode3D = LerpNode3D.new()
@export var right_hand_target: LerpNode3D = LerpNode3D.new()
@export var left_foot_target:  LerpNode3D = LerpNode3D.new()
@export var right_foot_target: LerpNode3D = LerpNode3D.new()

@export var reset_head := Transform3D.IDENTITY
@export var reset_hip := Transform3D.IDENTITY
@export var reset_left_hand := Transform3D.IDENTITY
@export var reset_right_hand := Transform3D.IDENTITY
@export var reset_left_foot := Transform3D.IDENTITY
@export var reset_right_foot := Transform3D.IDENTITY

#var ren_ik: RenIK3D = RenIK3D.new()
var ren_ik: AdaptedRenik = AdaptedRenik.new()

func _set_skeleton_a_pose() -> Error:
	if self.ren_ik.skeleton == null:
		push_error("Skeleton was None while trying to A-pose, this is a bug!")
		return ERR_UNCONFIGURED

	const L_SHOULDER := "LeftShoulder"
	const R_SHOULDER := "RightShoulder"
	const L_UPPER_ARM := "LeftUpperArm"
	const R_UPPER_ARM := "RightUpperArm"

	for bone_name in [L_SHOULDER, R_SHOULDER, L_UPPER_ARM, R_UPPER_ARM]:
		var bone_idx := self.ren_ik.skeleton.find_bone(bone_name)
		if bone_idx < 0:
			push_error("Bone not found while trying to A-pose: {bone_name}".format({bone_name = bone_name}))
			continue

		var euler := Vector3.ZERO

		match bone_name:
			L_SHOULDER:
				euler = Vector3(-PI/2, -PI/2, 0.0)
			L_UPPER_ARM:
				euler = Vector3(PI/4, PI, 0.0)
			R_SHOULDER:
				euler = Vector3(-PI/2, PI/2, 0.0)
			R_UPPER_ARM:
				euler = Vector3(PI/4, PI, 0.0)
			_:
				push_error("This should never happen, this is a major bug!")
				return ERR_BUG
		
		self.ren_ik.skeleton.set_bone_pose_rotation(bone_idx, Quaternion.from_euler(euler))
	
	return OK

func _align_target_with_skeleton():
	var skeleton := self.ren_ik.skeleton
	var tx := skeleton.global_transform
	
	var idx := skeleton.find_bone(self.ren_ik.armature_head)
	if idx >= 0: self.head_target.global_target = tx * skeleton.get_bone_global_pose(idx)
	idx = skeleton.find_bone(self.ren_ik.armature_hip)
	if idx >= 0: self.hip_target.global_target = tx * skeleton.get_bone_global_pose(idx)
	idx = skeleton.find_bone(self.ren_ik.armature_left_hand)
	if idx >= 0: self.left_hand_target.global_target = tx * skeleton.get_bone_global_pose(idx)
	idx = skeleton.find_bone(self.ren_ik.armature_right_hand)
	if idx >= 0: self.right_hand_target.global_target = tx * skeleton.get_bone_global_pose(idx)
	idx = skeleton.find_bone(self.ren_ik.armature_left_foot)
	if idx >= 0: self.left_foot_target.global_target = tx * skeleton.get_bone_global_pose(idx)
	idx = skeleton.find_bone(self.ren_ik.armature_right_foot)
	if idx >= 0: self.right_foot_target.global_target = tx * skeleton.get_bone_global_pose(idx)

func _add_ik_target_to_parent(parent: Node3D, target_name: StringName) -> Node3D:
	var ik_target := Node3D.new()
	ik_target.name = target_name
	parent.add_child(ik_target)
	ik_target.owner = parent
	return ik_target

func _initialize_lerp_nodes():
	var lerp_nodes = [ 
		self.head_target, self.hip_target,
		self.left_hand_target, self.right_hand_target,
		self.left_foot_target, self.right_foot_target
	]
	
	for n in lerp_nodes:
		if not self.is_ancestor_of(n):
			self.add_child(n)
			n.owner = self

func _setup_ik_targets(ik_target_config: Dictionary) -> Node3D:
	var skeleton_node = self.ren_ik.skeleton
	if not skeleton_node:
		push_error("Skeleton not set")
		return null
	
	var ik_parent_name: StringName = IK_TARGETS_NODE_PARENT_NAME
	self.ik_targets_parent = skeleton_node.find_child(ik_parent_name, false)
	if self.ik_targets_parent:
		for child in self.ik_targets_parent.get_children():
			child.owner = null
			self.ik_targets_parent.remove_child(child)
			child.queue_free()
	else:
		# Create node and add to tree
		self.ik_targets_parent = Node3D.new()
		self.ik_targets_parent.name = ik_parent_name
		skeleton_node.add_child(self.ik_targets_parent)
		self.ik_targets_parent.owner = skeleton_node
	
	# Create target Node3Ds
	self.ren_ik.armature_head_target = \
		self._add_ik_target_to_parent(self.ik_targets_parent, &"Head").get_path()
	self.ren_ik.armature_hip_target = \
		self._add_ik_target_to_parent(self.ik_targets_parent, &"Hip").get_path()
	self.ren_ik.armature_left_hand_target = \
		self._add_ik_target_to_parent(self.ik_targets_parent, &"LeftHand").get_path()
	self.ren_ik.armature_right_hand_target = \
		self._add_ik_target_to_parent(self.ik_targets_parent, &"RightHand").get_path()
	self.ren_ik.armature_left_foot_target = \
		self._add_ik_target_to_parent(self.ik_targets_parent, &"LeftFoot").get_path()
	self.ren_ik.armature_right_foot_target = \
		self._add_ik_target_to_parent(self.ik_targets_parent, &"RightFoot").get_path()
	
	# Link targets to nodes for automated processing
	self.head_target.target_node       = self.ren_ik.head_target_spatial
	self.hip_target.target_node        = self.ren_ik.hip_target_spatial
	self.left_hand_target.target_node  = self.ren_ik.hand_left_target_spatial
	self.right_hand_target.target_node = self.ren_ik.hand_right_target_spatial
	self.left_foot_target.target_node  = self.ren_ik.foot_left_target_spatial
	self.right_foot_target.target_node = self.ren_ik.foot_right_target_spatial
	
	# Load lerp configs
	var target_mapping = {
		IkTarget.HEAD:       self.head_target,
		IkTarget.HIP:        self.hip_target,
		IkTarget.LEFT_HAND:  self.left_hand_target,
		IkTarget.RIGHT_HAND: self.right_hand_target,
		IkTarget.LEFT_FOOT:  self.left_foot_target,
		IkTarget.RIGHT_FOOT: self.right_foot_target
	}
	for id in ik_target_config.keys():
		var target: LerpNode3D = target_mapping.get(id)
		var config = ik_target_config[id]
		if target and config is LerpNode3D.Config:
			target.load_config(config)
	
	return self.ik_targets_parent

## Returns skeleton armature poses. Return elements are of the form IkTargets: Transform3D
func get_skeleton_poses() -> Dictionary:
	var skeleton = self.ren_ik.skeleton
	if not skeleton:
		return {}
	
	var poses: Dictionary = {}
	var bone_targets = [
		[ IkTarget.HEAD,       self.ren_ik.armature_head ],
		[ IkTarget.HIP,        self.ren_ik.armature_hip ],
		[ IkTarget.LEFT_HAND,  self.ren_ik.armature_left_hand ],
		[ IkTarget.RIGHT_HAND, self.ren_ik.armature_right_hand ],
		[ IkTarget.LEFT_FOOT,  self.ren_ik.armature_left_foot ],
		[ IkTarget.RIGHT_FOOT, self.ren_ik.armature_right_foot ],
	]
	for bt in bone_targets:
		if not bt[1]:
			continue
		
		var idx = skeleton.find_bone(bt[1])
		if idx < 0:
			continue
		
		var pose = skeleton.global_transform * skeleton.get_bone_global_pose(idx)
		poses[bt[0]] = pose
	
	return poses

## Initialize IK. Sets up RenIk and initializes LerpNode3D targets.
## skeleton_node The skeleton to control.
## ik_target_bone_names Name of bones that RenIk needs to function. If this is a 
##                      VRM file, the bone mappings can be found in avatar_base.get_avatar().vrm_meta.humanoid_bone_mapping
## ik_target_config (Optional) dictionary of lerp configuration for various bones. Should contain elements of the form
##                  PuppeteerSkeletonIk.IkTarget: LerpNode3D.Config
func initialize(skeleton_node: Skeleton3D, ik_target_bone_names: IkTargetBoneNames, ik_target_config: Dictionary = {}):
	skeleton_node.reset_bone_poses()
	
	self._initialize_lerp_nodes()
	
	if not self.is_ancestor_of(self.ren_ik):
		self.add_child(self.ren_ik)
		self.ren_ik.owner = self
	
	# Link RenIk to skeleton_node
	self.ren_ik.armature_skeleton_path = skeleton_node.get_path()
	self.ren_ik.armature_head            = ik_target_bone_names.head
	self.ren_ik.armature_hip             = ik_target_bone_names.hip
	self.ren_ik.armature_left_hand       = ik_target_bone_names.left_hand
	self.ren_ik.armature_left_lower_arm  = ik_target_bone_names.left_lower_arm
	self.ren_ik.armature_left_upper_arm  = ik_target_bone_names.left_upper_arm
	self.ren_ik.armature_right_hand      = ik_target_bone_names.right_hand
	self.ren_ik.armature_right_lower_arm = ik_target_bone_names.right_lower_arm
	self.ren_ik.armature_right_upper_arm = ik_target_bone_names.right_upper_arm
	self.ren_ik.armature_left_foot       = ik_target_bone_names.left_foot
	self.ren_ik.armature_left_lower_leg  = ik_target_bone_names.left_lower_leg
	self.ren_ik.armature_left_upper_leg  = ik_target_bone_names.left_upper_leg
	self.ren_ik.armature_right_foot      = ik_target_bone_names.right_foot
	self.ren_ik.armature_right_lower_leg = ik_target_bone_names.right_lower_leg
	self.ren_ik.armature_right_upper_leg = ik_target_bone_names.right_upper_leg
	self.ren_ik.update_skeleton()
	
	self._set_skeleton_a_pose()
	
	self._setup_ik_targets(ik_target_config)
	self.ren_ik.update_skeleton()
	
	self._align_target_with_skeleton()
	self.set_reset_poses()

func update_puppet(_delta: float):
	self.ren_ik.update_ik()

func set_reset_poses():
	self.reset_head = self.head_target.global_target
	self.reset_hip  = self.hip_target.global_target
	self.reset_left_hand = self.left_hand_target.global_target
	self.reset_right_hand = self.right_hand_target.global_target
	self.reset_left_foot = self.left_foot_target.global_target
	self.reset_right_foot = self.right_foot_target.global_target

func reset_target_poses():
	self.head_target.global_target = self.reset_head
	self.hip_target.global_target = self.reset_hip
	self.left_hand_target.global_target = self.reset_left_hand
	self.right_hand_target.global_target = self.reset_right_hand
	self.left_foot_target.global_target = self.reset_left_foot
	self.right_foot_target.global_target = self.reset_right_foot
