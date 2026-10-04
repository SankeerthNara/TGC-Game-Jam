shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float halftone_strength : hint_range(0.0, 1.0) = 0.35;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.035;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform vec4 flash_color : source_color = vec4(0.9, 0.15, 0.2, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec2 shake_offset = vec2(0.0, 0.0);

// Ink color constant: #18151d
const vec3 INK_COLOR = vec3(0.094, 0.082, 0.114);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV + shake_offset;
	vec4 src = texture(screen_texture, uv);

	// 1. Luminance calculation
	float lum = dot(src.rgb, vec3(0.299, 0.587, 0.114));

	// 2. Subtle Halftone in dark areas
	// Screen-space rotated grid
	vec2 fc = FRAGCOORD.xy;
	float angle = 0.785398; // 45 degrees
	mat2 rot = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
	vec2 rot_coord = rot * fc;
	vec2 dot_grid = mod(rot_coord, 8.0) - vec2(4.0);
	float dist = length(dot_grid);
	
	// Dots appear in dark to mid-tone areas
	float dark_mask = smoothstep(0.7, 0.15, lum);
	float dot_radius = dark_mask * 3.2;
	float dot_factor = smoothstep(dot_radius + 0.5, dot_radius - 0.5, dist);
	vec3 halftone_rgb = mix(src.rgb, INK_COLOR, dot_factor * halftone_strength * dark_mask);

	// 3. Paper Grain
	float grain = (hash(fc) - 0.5) * grain_strength;
	vec3 grained_rgb = halftone_rgb + vec3(grain * 1.1, grain * 1.0, grain * 0.85);

	// 4. Ink Vignette
	vec2 v_uv = (uv - 0.5) * vec2(1.0, 0.85);
	float vig = smoothstep(0.35, 0.72, length(v_uv)) * vignette_strength;
	vec3 final_rgb = mix(grained_rgb, INK_COLOR, vig);

	// 5. Short Color Flash
	final_rgb = mix(final_rgb, flash_color.rgb, flash_amount * flash_color.a);

	COLOR = vec4(final_rgb, 1.0);
}
