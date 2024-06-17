extends Control


func _clear_post_processing_nodes():
	# Remove all post-processing nodes
	for child: Node in self.get_children():
		child.queue_free()

func deactivate_post_processing():
	# Reactivate viewport visibility
	get_node(Main.MAIN_NODE_PATH).get_avatar_viewport_container().visible = true
	
	# Remove all post-processing nodes
	return self._clear_post_processing_nodes()

func add_post_processing_node(node: Node, node_pos: int = -1) -> int:
	self.add_child(node)
	node.set_owner(self)
	
	if node_pos >= 0:
		self.move_child(node, node_pos)
		return node_pos
	else:
		return self.get_child_count() - 1

func remove_post_processing_node(node: Node, free_node: bool = true) -> int:
	self.remove_child(node)
	if free_node:
		node.queue_free()
	
	# Child is removed later, so decrement current child count
	var remaining_nodes: int = self.get_child_count() - 1
	if remaining_nodes <= 0:
		# Reactivate viewport visibility
		get_node(Main.MAIN_NODE_PATH).get_avatar_viewport_container().visible = true
	
	return remaining_nodes

func set_post_processing_chain(nodes: Array[Node], keep_avatar_viewport_visible: bool = false):
	get_node(Main.MAIN_NODE_PATH).get_avatar_viewport_container().visible = keep_avatar_viewport_visible
	
	self._clear_post_processing_nodes()
	for node in nodes:
		self.add_post_processing_node(node)
