class_name Pid
extends PidBase

var _perr: float = 0.0
var _icur: float = 0.0

func _init(icur: float = 0.0, perr: float = 0.0):
	self.reset(icur, perr)

func reset(icur: float = 0.0, perr: float = 0.0):
	self._icur = icur
	self._perr = perr

func update(current: float, target: float, dt: float) -> float:
	var err = target - current
	
	var derr   = clampf((err - self._perr)/dt, self.dmin, self.dmax)
	self._icur = clampf(self._icur + err * dt, self.imin, self.imax)
	
	self._perr = err
	return self.kp * err + self.ki * self._icur + self.kd * derr
