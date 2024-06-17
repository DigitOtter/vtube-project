uniform sampler2D project_texture : source_color, hint_default_white, filter_linear;

#include "./gauss_blur.gdshaderinc"

vec3 color_mix(vec3 base, vec3 overlay)
{
	return base*overlay;
}

vec3 color_screen(vec3 base, vec3 overlay)
{
	return vec3(1.0) - (vec3(1.0) - vec3(base.xyz)) * (vec3(1.0) - vec3(overlay.xyz));
}

vec3 color_soft_light(vec3 base, vec3 overlay)
{
	vec3 out_col;
	{
		float base = base.x;
		float blend = overlay.x;
		if (base < 0.5) {
			out_col.x = (base * (blend + 0.5));
		} else {
			out_col.x = (1.0 - (1.0 - base) * (1.0 - (blend - 0.5)));
		}
	}
	{
		float base = base.y;
		float blend = overlay.y;
		if (base < 0.5) {
			out_col.y = (base * (blend + 0.5));
		} else {
			out_col.y = (1.0 - (1.0 - base) * (1.0 - (blend - 0.5)));
		}
	}
	{
		float base = base.z;
		float blend = overlay.z;
		if (base < 0.5) {
			out_col.z = (base * (blend + 0.5));
		} else {
			out_col.z = (1.0 - (1.0 - base) * (1.0 - (blend - 0.5)));
		}
	}
	
	return out_col;
}

vec3 color_overlay(vec3 base, vec3 overlay)
{
	vec3 out_col;
	{
		float base = base.x;
		float blend = overlay.x;
		if (base < 0.5) {
			out_col.x = 2.0 * base * blend;
		} else {
			out_col.x = 1.0 - 2.0 * (1.0 - blend) * (1.0 - base);
		}
	}
	{
		float base = base.y;
		float blend = overlay.y;
		if (base < 0.5) {
			out_col.y = 2.0 * base * blend;
		} else {
			out_col.y = 1.0 - 2.0 * (1.0 - blend) * (1.0 - base);
		}
	}
	{
		float base = base.z;
		float blend = overlay.z;
		if (base < 0.5) {
			out_col.z = 2.0 * base * blend;
		} else {
			out_col.z = 1.0 - 2.0 * (1.0 - blend) * (1.0 - base);
		}
	}
	
	return out_col;
}

vec3 project(vec3 base_color, vec2 screen_uv)
{
	screen_uv = clamp(screen_uv, vec2(0,0), vec2(1,1));
	vec3 tex_col = texture(project_texture, screen_uv).rgb;
	return color_mix(base_color, tex_col);
}