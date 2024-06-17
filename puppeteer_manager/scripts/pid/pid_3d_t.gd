class_name Pid3DT
extends Node

@export var target: Vector3 = Vector3.ZERO
@export var out: Vector3    = Vector3.ZERO

@export var pid_3d: Pid3D = Pid3D.new()

func _init(out: Vector3 = Vector3.ZERO, icur: float = 0.0, perr: float = 0.0):
	self.reset(out, icur, perr)

func _physics_process(delta):
	self.out = self.pid_3d.update_3d(self.out, self.target, delta)

func reset(out: Vector3 = Vector3.ZERO, icur: float = 0.0, perr: float = 0.0):
	self.out  = out
	self.pid_3d.reset(icur, perr)
