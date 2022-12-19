// NOTE: Shader automatically converted from Godot Engine 4.0.beta8's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;
uniform sampler2D texture_emission : source_color, hint_default_black,filter_linear_mipmap,repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

varying float alpha;

void vertex() {
	float f = VERTEX.y;
	VERTEX = vec3(VERTEX.x, 1.0 + -f * f, VERTEX.z - f - 1.0);
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	
	alpha = pow(clamp(1.0 - f, 0.0, 1.0), 3);
}

void fragment() {
	ALBEDO = vec3(0, 0, 0);
	EMISSION = emission.rgb;
	ALPHA = alpha;
}
