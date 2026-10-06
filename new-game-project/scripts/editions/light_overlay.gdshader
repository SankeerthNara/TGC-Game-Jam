shader_type canvas_item;
// The light is gone: the scene is darkened except around light sources (the hero's glow, lamps,
// candles, glowing orbs). The HUD bands at the top and bottom stay clear.

uniform float darkness = 0.55;      // 0..1 how dark the unlit scene is
uniform vec3 dark_col = vec3(0.02, 0.03, 0.06);
uniform vec3 warm = vec3(1.0, 0.78, 0.45);
uniform int count = 0;
uniform vec4 lights[24];            // x, y (screen px), radius px, intensity
uniform float hud_top = 130.0;      // rows above stay clear (the HUD)
uniform float hud_bottom = 640.0;   // rows below stay clear

void fragment() {
	vec2 p = UV * vec2(1280.0, 720.0); // the rect covers the 1280x720 game screen
	float lit = 0.0;
	for (int i = 0; i < 24; i++) {
		if (i >= count) { break; }
		vec4 l = lights[i];
		float d = length(p - l.xy) / max(l.z, 1.0);
		float f = clamp(1.0 - d, 0.0, 1.0);
		lit += f * f * l.w;
	}
	lit = clamp(lit, 0.0, 1.0);
	// the HUD keeps its own brightness
	float hud = (p.y < hud_top || p.y > hud_bottom) ? 1.0 : 0.0;
	float a = darkness * (1.0 - lit) * (1.0 - hud);
	// a faint warm tint inside the pools of light
	vec3 col = mix(dark_col, warm, lit * 0.35);
	float tint = lit * 0.10 * (1.0 - hud);
	COLOR = vec4(col, max(a, tint));
}
