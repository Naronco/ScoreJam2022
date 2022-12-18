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
uniform float specular : hint_range(0,1);
uniform float metallic : hint_range(0,1);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

varying vec3 view_pos;
varying vec3 world_pos;
varying vec3 player_view;
global uniform vec3 player_pos;
global uniform float circle_scale;
global uniform float camera_distance;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	view_pos = (VIEW_MATRIX * vec4(world_pos, 1.0)).xyz;
	player_view = (VIEW_MATRIX * vec4(player_pos + vec3(0, 1, 0), 1)).xyz;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	
	bool outside = false;
	
	float hole;
	if (outside)
	{
		hole = smoothstep(1.0, 0.0, (world_pos.y - player_pos.y) * 0.5 - 0.2);
	}
	else
	{
		hole = length(view_pos.xy - player_view.xy) / (0.9 * circle_scale);
		hole = min(hole, 1.0 - (view_pos.z + camera_distance - 1.0) / 3.0);
		hole = max(hole, max(
			player_pos.x - (world_pos.x - 2.0),
			player_pos.z - (world_pos.z - 2.0)
		) / 2.0);
		hole = max(hole, smoothstep(1.0, 0.0, (world_pos.y - player_pos.y) * 0.5 - 0.2));
	}

	{
		const vec3 magic = vec3(0.06711056f, 0.00583715f, 52.9829189f);	
		float fade = clamp(smoothstep(0.9, 1.0, hole), 0.0, 1.0);
		if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
			discard;
		}
	}
}

