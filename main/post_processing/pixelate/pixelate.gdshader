/*
Shader from Godot Shaders - the free shader library.
https://godotshaders.com/shader/pixelate

This shader is under CC0 license. Feel free to use, improve and 
change this shader according to your needs and consider sharing 
the modified result to godotshaders.com.
*/

shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform int amount = 40;
uniform sampler2D input_texture: repeat_disable, filter_nearest;

void fragment()
{
	vec2 grid_uv = round(UV * float(amount)) / float(amount);
	
	vec4 text = texture(input_texture, grid_uv);
	
	COLOR = text;
}