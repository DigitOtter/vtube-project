shader_type spatial;
render_mode unshaded, diffuse_toon, specular_disabled, depth_prepass_alpha;

uniform vec2 border_width = vec2(0.01, 0.01);
uniform vec4 border_color: source_color = vec4(1.0, 1.0, 0.0, 1.0);

void fragment() {
	ALBEDO = border_color.rgb;
	if(UV.x > border_width.x && UV.x < 1.0-border_width.x &&
	   UV.y > border_width.y && UV.y < 1.0-border_width.y)
		ALPHA = 0.0;
	else
		ALPHA = border_color.a;
}
