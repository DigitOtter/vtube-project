class_name TrackerVrmUtils

static func get_vrm_ik_bone_names(avatar_root: Node) -> PuppeteerSkeletonIk.IkTargetBoneNames:
	var ik_bone_names:= PuppeteerSkeletonIk.IkTargetBoneNames.new()
	
	var vrm_bone_map: BoneMap = PuppeteerBase.get_vrm_bone_mappings(avatar_root)
	if vrm_bone_map:
		var armature_name:= vrm_bone_map.get_skeleton_bone_name(&"hips")
		if armature_name: ik_bone_names.hip = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"head")
		if armature_name: ik_bone_names.head = armature_name
		
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"leftUpperArm")
		if armature_name: ik_bone_names.left_upper_arm = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"leftLowerArm")
		if armature_name: ik_bone_names.left_lower_arm = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"leftHand")
		if armature_name: ik_bone_names.left_hand = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"rightUpperArm")
		if armature_name: ik_bone_names.right_upper_arm = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"rightLowerArm")
		if armature_name: ik_bone_names.right_lower_arm = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"rightHand")
		if armature_name: ik_bone_names.right_hand = armature_name
		
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"leftUpperLeg")
		if armature_name: ik_bone_names.left_upper_leg = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"leftLowerLeg")
		if armature_name: ik_bone_names.left_lower_leg = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"leftFoot")
		if armature_name: ik_bone_names.left_foot = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"rightUpperLeg")
		if armature_name: ik_bone_names.right_upper_leg = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"rightLowerLeg")
		if armature_name: ik_bone_names.right_lower_leg = armature_name
		armature_name = vrm_bone_map.get_skeleton_bone_name(&"rightFoot")
		if armature_name: ik_bone_names.right_foot = armature_name
	
	return ik_bone_names
