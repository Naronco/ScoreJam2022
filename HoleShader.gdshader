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
global uniform bool player_outside;
global uniform float circle_scale;
global uniform float camera_distance;
global uniform bool in_editor;

#define camera_rotation 0.0
//((-15.0) / 180.0 * 3.14159268)

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	view_pos = (VIEW_MATRIX * vec4(world_pos, 1.0)).xyz;
	player_view = (VIEW_MATRIX * vec4(player_pos + vec3(0, 1, 0), 1)).xyz;
}

void fragment() {
	float is_back_wall = max(0.0, MODEL_MATRIX[3].y * 1000.0);
	float is_inside_wall = max(0.0, MODEL_MATRIX[3].y * -1000.0);
	
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);

	if (in_editor) {
		ALBEDO = albedo.rgb * albedo_tex.rgb + vec3(0.0, is_back_wall * 0.2, is_inside_wall * 0.3);
	} else {
		ALBEDO = albedo.rgb * albedo_tex.rgb;
	}
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	
	float hole;
	float sinrot = sin(camera_rotation);
	float cosrot = cos(camera_rotation);
	
	vec3 axis1 = vec3(cosrot, 0.0, -sinrot);
	vec3 axis2 = vec3(sinrot, 0.0, cosrot);
	
	vec3 world_axis1_offset = player_pos - (world_pos + (-2.0 + 2.0 * is_back_wall * (player_outside ? 0.0 : 1.0)) * axis1);
	vec3 world_axis2_offset = player_pos - (world_pos + (-2.0 + 2.0 * is_back_wall * (player_outside ? 0.0 : 1.0)) * axis2);
	
	float ortho_fade_offset_x = 8.0 / circle_scale * (1.0 - is_inside_wall);
	float ortho_fade_offset_z = 10.0 / circle_scale * (1.0 - is_inside_wall);
	float ortho_fade_scale = 3.0 + 7.0 * (1.0 - is_inside_wall);

	if (is_back_wall > 0.5 || in_editor) {
		if (player_outside) {
			hole = 0.0;
		} else {
			hole = 1.0;
		}
	} else if (is_inside_wall > 0.5 && player_outside) {
		hole = 1.0;
	} else {
		//if (player_outside) {
			hole = 0.0;
		/*} else {
			hole = length(view_pos.xy - player_view.xy) / (0.9 * circle_scale);
		}*/
		hole = max(hole, max(
			player_pos.x - (world_pos.x - ortho_fade_offset_x),
			player_pos.z - (world_pos.z - ortho_fade_offset_z)
		) / ortho_fade_scale);
		if (!player_outside) {
			hole = min(hole, 1.0 - (view_pos.z + camera_distance - 1.0 - 5.0 * is_inside_wall) / 3.0);
		}
	}
	
	hole = max(hole, smoothstep(1.0, 0.0, (world_pos.y - player_pos.y) * 0.5 - 0.2 * circle_scale));
	hole = clamp(hole, 0.0, 1.0);

	{
		const vec3 magic = vec3(0.06711056f, 0.00583715f, 52.9829189f);	
		float fade = clamp(smoothstep(0.9, 1.0, hole), 0.0, 1.0);
		if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
			discard;
		}
	}
}

