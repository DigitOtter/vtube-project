class_name TrackerVrmUtils

static func get_vrm_ik_bone_names(_avatar_base: AvatarBase) -> PuppeteerSkeletonIk.IkTargetBoneNames:
	var ik_bone_names:= PuppeteerSkeletonIk.IkTargetBoneNames.new()
	
	#var vrm_bone_map: BoneMap = PuppeteerBase.get_vrm_bone_mappings(avatar_base)
	#if vrm_bone_map:
		#var armature_name:= vrm_bone_map.get_skeleton_bone_name(&"Hips")
		#if armature_name: ik_bone_names.hip = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"Head")
		#if armature_name: ik_bone_names.head = armature_name
		#
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"LeftUpperArm")
		#if armature_name: ik_bone_names.left_upper_arm = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"LeftLowerArm")
		#if armature_name: ik_bone_names.left_lower_arm = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"LeftHand")
		#if armature_name: ik_bone_names.left_hand = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"RightUpperArm")
		#if armature_name: ik_bone_names.right_upper_arm = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"RightLowerArm")
		#if armature_name: ik_bone_names.right_lower_arm = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"RightHand")
		#if armature_name: ik_bone_names.right_hand = armature_name
		#
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"LeftUpperLeg")
		#if armature_name: ik_bone_names.left_upper_leg = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"LeftLowerLeg")
		#if armature_name: ik_bone_names.left_lower_leg = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"LeftFoot")
		#if armature_name: ik_bone_names.left_foot = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"RightUpperLeg")
		#if armature_name: ik_bone_names.right_upper_leg = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"RightLowerLeg")
		#if armature_name: ik_bone_names.right_lower_leg = armature_name
		#armature_name = vrm_bone_map.get_skeleton_bone_name(&"RightFoot")
		#if armature_name: ik_bone_names.right_foot = armature_name
	
	return ik_bone_names
