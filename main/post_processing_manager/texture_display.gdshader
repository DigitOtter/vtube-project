shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D view_texture: hint_default_black, repeat_disable, filter_linear;

void fragment() {
	COLOR = texture(view_texture, UV);
}
