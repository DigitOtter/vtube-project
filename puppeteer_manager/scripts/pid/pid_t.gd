class_name PidT
extends Node

@export var target: float = 0.0
@export var out: float = 0.0

@export var pid: Pid = Pid.new()

func _init(out: float = 0.0, icur: float = 0.0, perr: float = 0.0):
	self.reset(out, icur, perr)

func _physics_process(delta):
	self.out = self.pid.update(self.target, delta)

func reset(out: float = 0.0, icur: float = 0.0, perr: float = 0.0):
	self.out  = out
	self.pid.reset(icur, perr)
