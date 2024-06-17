## Directly assigns skeleton transformations. Used by VMC Receiver
class_name PuppeteerSkeletonDirect
extends    PuppeteerBase

var skeleton: Skeleton3D
var bone_poses: Dictionary = {}

var vmc_to_bone_idx: Dictionary

func __utg_01_convert(u: Vector3) -> Vector3:
	return Vector3(u.x, -u.y, -u.z)

func __utg_02l_convert(u: Vector3) -> Vector3:
	return Vector3(u.z, -u.y, u.x)

func __utg_02r_convert(u: Vector3) -> Vector3:
	return Vector3(-u.z, -u.y, u.x)

var __utg_converters: Dictionary = {
	'hips': self.__utg_01_convert,
	'spine': self.__utg_01_convert,
	'chest': self.__utg_01_convert,
	'upper_chest': self.__utg_01_convert,
	'neck': self.__utg_01_convert,
	'head': self.__utg_01_convert,
	'leftupperarm': self.__utg_02l_convert,
	'rightupperarm': self.__utg_02r_convert,
}

var _goggles_idx: int = -1
@export var goggle_toggle: bool = false
var _goggle_on: bool = false
var _goggles_on_pose: Transform3D = Transform3D(
	Basis(	Quaternion.from_euler(Vector3(25.5/180.0*PI, 0.0, 0.0))),
			Vector3(0.0, 0.10, -0.01))

func initialize(skeleton: Skeleton3D, bone_mapping: BoneMap):
	self.skeleton = skeleton
	
	# Invert bone mapping
	self.vmc_to_bone_idx.clear()
	for i in range(0, bone_mapping.profile.bone_size):
		var profile_bone_name: String = bone_mapping.profile.get_bone_name(i)
		var skel_bone_name: String = bone_mapping.get_skeleton_bone_name(profile_bone_name)
		if skel_bone_name:
			var bone_data = [self.skeleton.find_bone(profile_bone_name),
				self.__utg_converters.get(profile_bone_name.to_lower(), self.__utg_01_convert)
			]
			self.vmc_to_bone_idx[profile_bone_name] = bone_data
		
	
	self._goggles_idx = self.skeleton.find_bone('goggles')

func update_puppet(delta: float):
	if self.goggle_toggle:
		self.goggle_toggle = false
		self._goggle_on = !self._goggle_on
		if self._goggle_on:
			self.skeleton.set_bone_pose_position(self._goggles_idx, self._goggles_on_pose.origin)
			self.skeleton.set_bone_pose_rotation(self._goggles_idx, Quaternion(self._goggles_on_pose.basis))
		else:
			self.skeleton.reset_bone_pose(self._goggles_idx)

	
	# TODO: Add bone stiffness and/or compare to vmc_receiver.t?
	for bone_name in self.bone_poses:
		var bone_data = self.vmc_to_bone_idx.get(bone_name, null)
		#if bone_name.to_lower() != 'head' and \
		#		bone_name.to_lower() != 'neck':
		#	continue
		if bone_data:
			var bone_idx = bone_data[0]
			var converter = bone_data[1]
			var bone_pose = self.bone_poses[bone_name]
			var rest_pose = self.skeleton.get_bone_rest(bone_idx).basis.get_euler()
			
			# Convert from Unity to Godot coordinate system
			# At the moment, we're only changing rotation and ignoring translation
			var euler = bone_pose.basis.get_euler()
			euler = converter.call(euler)
			
			self.skeleton.set_bone_pose_rotation(bone_idx, Quaternion.from_euler(rest_pose)*Quaternion.from_euler(euler))
