class_name Pid3D
extends Pid

func update_3d(current: Vector3, target: Vector3, dt: float) -> Vector3:
	var dist = target - current
	var err: float = dist.length()
	
	var derr: float = clampf((err - self._perr)/dt, self.dmin, self.dmax)
	
	self._icur = clampf(self._icur + err * dt, self.imin, self.imax)
	
	self._perr = err
	return dist * ((self.kp * err + self.ki * self._icur + self.kd * derr)/err)
