class_name PidBase
extends Resource

class PidConfig:
	var kp: float = 1.0
	var ki: float = 0.0
	var kd: float = 0.0
	
	var imin: float = -INF
	var imax: float = INF
	var dmin: float = -INF
	var dmax: float = INF

@export var kp: float = 1.0
@export var ki: float = 0.0
@export var kd: float = 0.0

@export var imin: float = -INF
@export var imax: float = INF

@export var dmin: float = -INF
@export var dmax: float = INF

func save_config() -> PidConfig:
	var config: PidConfig = PidConfig.new()
	config.kp = self.kp
	config.ki = self.ki
	config.kd = self.kd
	
	config.imin = self.imin
	config.imax = self.imax
	config.dmin = self.dmin
	config.dmax = self.dmax
	
	return config

func load_config(config: PidConfig):
	self.kp = config.kp
	self.ki = config.ki
	self.kd = config.kd
	
	self.imin = config.imin
	self.imax = config.imax
	self.dmin = config.dmin
	self.dmax = config.dmax
