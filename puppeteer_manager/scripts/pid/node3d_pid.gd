class_name Node3DPid
extends Node3D

@export
var pid: Pid3D

@export
var global_target_pos: Vector3

func _ready():
	self.pid.reset()

func _physics_process(delta):
	# On each physics_process, update the node's position
	self.global_position = self.pid.update_3d(self.global_position, self.global_target_pos, delta)
