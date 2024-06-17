shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon, unshaded;

#include "./project_image.gdshaderinc"

uniform vec3 object_color : source_color = vec3(0,0,0);

void fragment() {
	ALBEDO   = project(object_color, SCREEN_UV);
	EMISSION = project(object_color, SCREEN_UV);
}
