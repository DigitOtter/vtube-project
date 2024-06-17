extends Node

const PUPPETEER_MANAGER_NODE_PATH: NodePath = "/root/PuppeteerManager"

enum PuppeteerType {
	SKELETON,
	BLEND_SHAPES
}

signal puppeteer_ready(avatar_root: Node)

## Should have the form TrackerBase: Array[ PuppeteerBase ]
var _registered_trackers: Dictionary = {}

var _puppeteers:    Array[PuppeteerBase] = []

## This function is connected to each tracker's tree_exiting signal
func _on_tracker_exit(tracker: TrackerBase):
	self.remove_tracker_puppeteers(tracker)

## Remove puppeteer from tree and from _puppeteers. Should be called after all references to
## puppeteer have been removed from _registered_trackers.
func _remove_puppeteer_from_tree(puppeteer: PuppeteerBase):
	puppeteer.owner = null
	if puppeteer.get_parent() == self:
		self.remove_child(puppeteer)
	self._puppeteers.erase(puppeteer)
	puppeteer.queue_free()

func _get_or_add_tracker(tracker: TrackerBase) -> Array:
	var reg_puppeteers = self._registered_trackers.get(tracker)
	if not reg_puppeteers:
		reg_puppeteers = []
		self._registered_trackers[tracker] = reg_puppeteers
		
		# Ensure that puppeteers are removed when the associated tracker is deleted
		tracker.connect("tree_exiting", func(): self._on_tracker_exit(tracker))
	
	return reg_puppeteers

func _on_avatar_loaded(avatar_root: Node):
	self.emit_signal(&"puppeteer_ready", avatar_root)

func _ready():
	var main_node: Main = get_node(Main.MAIN_NODE_PATH)
	main_node.connect_avatar_loaded(self._on_avatar_loaded)

func _process(delta):
	# Process all puppeteers in order
	for p in self._puppeteers:
		p.update_puppet(delta)

func request_new_puppeteer(tracker: TrackerBase, type: PuppeteerBase.Type) -> PuppeteerBase:
	var new_puppeteer: PuppeteerBase = PuppeteerBase.create_new(type)
	if not new_puppeteer:
		return null
	
	var reg_puppeteers = self._get_or_add_tracker(tracker)
	reg_puppeteers.append(new_puppeteer)
	self._puppeteers.append(new_puppeteer)
	
	self.add_child(new_puppeteer)
	new_puppeteer.owner = self
	
	return new_puppeteer

func remove_puppeteer(puppeteer: PuppeteerBase):
	# Remove from registered trackers
	for tpups: Array in self._registered_trackers.values():
		tpups.erase(puppeteer)
	
	self._remove_puppeteer_from_tree(puppeteer)

func remove_tracker_puppeteers(tracker: TrackerBase):
	var reg_puppeteers = self._registered_trackers.get(tracker, [])
	self._registered_trackers.erase(tracker)
	
	for p in reg_puppeteers:
		self._remove_puppeteer_from_tree(p)

func update_puppeteer_order():
	# TODO
	pass
