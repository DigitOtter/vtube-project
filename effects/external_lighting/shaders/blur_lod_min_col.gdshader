shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur: hint_range(0.0, 50.0);
uniform vec3 min_col: source_color = vec3(0.1,0.1,0.1);

void fragment() {
	COLOR.rgb = max(textureLod(screen_texture, SCREEN_UV, blur).rgb, min_col);
}
