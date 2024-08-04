class_name LerpNode3D
extends Node

class Config:
	var lerp_rate: float = 0.1

@export var target_node: Node3D          = null

@export var global_target: Transform3D = Transform3D.IDENTITY
@export var lerp_rate: float           = 7.5

func _physics_process(delta):
	# For the future, maybe use https://blog.pkh.me/p/41-fixing-the-iterative-damping-interpolation-in-video-games.html
	if self.target_node:
		#self.target_node.global_transform = self.global_target
		self.target_node.global_transform = \
			self.target_node.global_transform.interpolate_with(self.global_target, delta*self.lerp_rate)

func save_config() -> Config:
	var config := Config.new()
	config.lerp_rate = self.lerp_rate
	return config

func load_config(config: Config):
	self.lerp_rate = config.lerp_rate

func align_target_with_node_pose():
	self.global_target = target_node.global_transform

func set_target_pose(pose: Transform3D):
	self.global_target = pose

func set_target_position(position: Vector3):
	self.global_target.origin = position

func set_target_basis(basis: Basis):
	self.global_target.basis = basis

func set_target_rotation(euler: Vector3):
	self.global_target.basis = Basis.from_euler(euler)
