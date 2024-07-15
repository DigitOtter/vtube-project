class_name GazeComputation
extends Resource

signal set_horizontal_gaze_strength(val: float, propagate: bool)
signal set_vertical_gaze_strength(val: float, propagate: bool)

signal set_horizontal_gaze_offset(val: float, propagate: bool)
signal set_vertical_gaze_offset(val: float, propagate: bool)

var _horizontal_gaze_strength := 1.0
var _vertical_gaze_strength := 1.0

var _horizontal_gaze_offset := 0.0
var _vertical_gaze_offset := 0.0

static func get_gaze_direction_from_mp(categories: Array[MediaPipeCategory]) -> Array[float]:
	# LookDown: 11,12 (L,R)
	# LookIn:   13,14 (L,R)
	# LookOut:  15,16 (L,R)
	# LookUp:   17,18 (L,R)
	var horizontal_ratio: float = (categories[13].score + categories[16].score)/2 - (categories[15].score + categories[14].score)/2
	var vertical_ratio: float =   (categories[17].score + categories[18].score)/2 - (categories[11].score + categories[12].score)/2
	
	return [ horizontal_ratio, vertical_ratio ]

## Computes gaze direction from PerfectSync blendshapes
## Input is PuppeteerTrackTree._blend_nodes
static func get_gaze_direction_from_blend_shapes(blend_nodes: Dictionary) -> Array[float]:
	var horizontal_ratio: float = \
		(blend_nodes[&"eyelookinleft"].target + blend_nodes[&"eyelookoutright"].target)/2 - \
		(blend_nodes[&"eyelookinright"].target + blend_nodes[&"eyelookoutleft"].target)/2
	var vertical_ratio: float = \
		(blend_nodes[&"eyelookupleft"].target + blend_nodes[&"eyelookupright"].target)/2 - \
		(blend_nodes[&"eyelookdownright"].target + blend_nodes[&"eyelookdownleft"].target)/2
	
	return [ horizontal_ratio, vertical_ratio ]

static func _compute_gaze(gaze: Array[float]) -> Array[TrackUtils.TrackTarget]:
	const TrackTarget = TrackUtils.TrackTarget
	var gaze_shapes: Array[TrackUtils.TrackTarget] = [
		TrackTarget.new(), TrackTarget.new(), TrackTarget.new(), TrackTarget.new()
	]
	gaze_shapes[0].name = "lookdown"
	gaze_shapes[1].name = "lookleft"
	gaze_shapes[2].name = "lookright"
	gaze_shapes[3].name = "lookup"
	
	if gaze[0] < 0:
		gaze_shapes[1].target = -gaze[0]
		gaze_shapes[2].target = 0
	else:
		gaze_shapes[1].target = 0
		gaze_shapes[2].target = gaze[0]
	if gaze[1] < 0:
		gaze_shapes[0].target = -gaze[1]
		gaze_shapes[3].target = 0
	else:
		gaze_shapes[0].target = 0
		gaze_shapes[3].target = gaze[1]
	
	return gaze_shapes

func _apply_gaze_parameters(gaze: Array[float]) -> void:
	gaze[0] = clampf(gaze[0] * self._horizontal_gaze_strength + self._horizontal_gaze_offset, -1.0, 1.0)
	gaze[1] = clampf(gaze[1] * self._vertical_gaze_strength + self._vertical_gaze_offset,     -1.0, 1.0)

func generate_gui_elements() -> Array[GuiElement.ElementData]:
	var elements: Array[GuiElement.ElementData] = []
	var horizontal_strength := GuiElement.ElementData.new()
	horizontal_strength.Name = "Horizontal Gaze Strength"
	horizontal_strength.OnDataChangedCallable = func(val: float): self._horizontal_gaze_strength = val
	horizontal_strength.SetDataSignal = [ self, &"set_horizontal_gaze_strength"]
	horizontal_strength.Data = GuiElement.SliderData.new()
	horizontal_strength.Data.Default = self._horizontal_gaze_strength
	horizontal_strength.Data.MaxValue = 5.0
	horizontal_strength.Data.MinValue = 0.0
	horizontal_strength.Data.Step = 0.1
	elements.append(horizontal_strength)
	
	var vertical_strength := GuiElement.ElementData.new()
	vertical_strength.Name = "Vertical Gaze Strength"
	vertical_strength.OnDataChangedCallable = func(val: float): self._vertical_gaze_strength = val
	vertical_strength.SetDataSignal = [ self, &"set_vertical_gaze_strength"]
	vertical_strength.Data = GuiElement.SliderData.new()
	vertical_strength.Data.Default = self._vertical_gaze_strength
	vertical_strength.Data.MaxValue = 5.0
	vertical_strength.Data.MinValue = 0.0
	vertical_strength.Data.Step = 0.1
	elements.append(vertical_strength)
	
	var horizontal_offset := GuiElement.ElementData.new()
	horizontal_offset.Name = "Horizontal Gaze Offset"
	horizontal_offset.OnDataChangedCallable = func(val: float): self._horizontal_gaze_offset = val
	horizontal_offset.SetDataSignal = [ self, &"set_horizontal_gaze_offset"]
	horizontal_offset.Data = GuiElement.SliderData.new()
	horizontal_offset.Data.Default = self._horizontal_gaze_offset
	horizontal_offset.Data.MaxValue = 1.0
	horizontal_offset.Data.MinValue = -1.0
	horizontal_offset.Data.Step = 0.01
	elements.append(horizontal_offset)
	
	var vertical_offset := GuiElement.ElementData.new()
	vertical_offset.Name = "Vertical Gaze Offset"
	vertical_offset.OnDataChangedCallable = func(val: float): self._vertical_gaze_offset = val
	vertical_offset.SetDataSignal = [ self, &"set_vertical_gaze_offset"]
	vertical_offset.Data = GuiElement.SliderData.new()
	vertical_offset.Data.Default = self._vertical_gaze_offset
	vertical_offset.Data.MaxValue = 1.0
	vertical_offset.Data.MinValue = -1.0
	vertical_offset.Data.Step = 0.01
	elements.append(vertical_offset)
	
	return elements

func compute_gaze_from_mp(blend_shapes: Array[MediaPipeCategory]) -> Array[TrackUtils.TrackTarget]:
	var gaze := GazeComputation.get_gaze_direction_from_mp(blend_shapes)
	self._apply_gaze_parameters(gaze)
	return GazeComputation._compute_gaze(gaze)

## Computes gaze direction from PerfectSync blendshapes
## Input is PuppeteerTrackTree._blend_nodes
func compute_gaze_from_blend_shapes(blend_nodes: Dictionary) -> Array[TrackUtils.TrackTarget]:
	var gaze := GazeComputation.get_gaze_direction_from_blend_shapes(blend_nodes)
	self._apply_gaze_parameters(gaze)
	return GazeComputation._compute_gaze(gaze)
