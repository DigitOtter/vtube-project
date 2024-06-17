#include "./project_image.gdshaderinc"

uniform sampler2D object_texture : source_color, filter_linear, repeat_enable;

void fragment() {
	vec4 tex_col = texture(object_texture,UV);
	ALBEDO = project(tex_col.rgb, SCREEN_UV);
	EMISSION = tex_col.rgb;
	ALPHA *= tex_col.a;
}
