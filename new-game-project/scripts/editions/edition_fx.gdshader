shader_type canvas_item;
// The "edition" of the picture: renders the whole screen at a lower resolution (144p crushed, 720p
// crisp pixel art), with colour crushing, softness, scanlines and digital glitches.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec2 res = vec2(256.0, 144.0);
uniform float soft = 0.0;       // 0..1 blur between low-res pixels (144p mush)
uniform float levels = 24.0;    // colour levels per channel
uniform float glitch = 0.0;     // 0..1 tearing and colour split
uniform float scan = 0.0;       // 0..1 scanline darkness
uniform float noise = 0.0;      // 0..1 grain
uniform float time = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec3 grab(vec2 uv) {
	vec2 px = (floor(uv * res) + 0.5) / res;
	vec3 c = texture(screen_tex, px).rgb;
	if (soft > 0.0) {
		vec2 d = 1.0 / res;
		vec3 n = texture(screen_tex, px + vec2(d.x, 0.0)).rgb + texture(screen_tex, px - vec2(d.x, 0.0)).rgb
			+ texture(screen_tex, px + vec2(0.0, d.y)).rgb + texture(screen_tex, px - vec2(0.0, d.y)).rgb;
		c = mix(c, n * 0.25, soft * 0.6);
	}
	return c;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	if (glitch > 0.0) {
		float band = floor(uv.y * 28.0 + floor(time * 9.0) * 3.0);
		float r = hash(vec2(band, floor(time * 14.0)));
		if (r < glitch * 0.45) {
			uv.x += (r - 0.2) * 0.18 * glitch;
		}
	}
	vec3 c = grab(uv);
	if (glitch > 0.0) {
		c.r = grab(uv + vec2(0.008 * glitch, 0.0)).r;
		c.b = grab(uv - vec2(0.008 * glitch, 0.0)).b;
	}
	c = floor(c * levels + 0.5) / levels;
	if (scan > 0.0) {
		float line = step(0.5, fract(uv.y * res.y));
		c *= 1.0 - scan * 0.35 * line;
	}
	if (noise > 0.0) {
		c += (hash(floor(uv * res) + floor(time * 18.0)) - 0.5) * noise * 0.12;
	}
	COLOR = vec4(c, 1.0);
}
