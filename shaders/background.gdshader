shader_type canvas_item;
// Sfondo psichedelico ancorato al mondo: onde di micelio, griglia di spore e vignetta che cambia colore.

uniform vec2 cam_pos = vec2(0.0);
uniform vec2 screen_size = vec2(1280.0, 720.0);
uniform float intensity = 0.5;
uniform float pulse = 0.0;

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec2 world = cam_pos + (UV - 0.5) * screen_size;
	float t = TIME;
	float d = length(world - cam_pos);
	vec2 p = world * 0.004;
	float n = sin(p.x * 3.0 + sin(p.y * 2.0 + t * 0.3) * 2.0) + sin(p.y * 3.5 + sin(p.x * 2.5 - t * 0.25) * 2.0);
	float waves = sin(d * 0.02 - t * 2.0 + n);
	// filamenti di micelio
	float fil = abs(sin(p.x * 9.0 + n * 2.0) * sin(p.y * 7.0 - n * 1.5));
	fil = smoothstep(0.04, 0.0, fil);
	// griglia di spore
	vec2 cell = fract(world / 64.0) - 0.5;
	float dotr = 0.07 + 0.09 * (waves * 0.5 + 0.5);
	float dots = smoothstep(dotr, dotr - 0.05, length(cell));
	float hue = fract(t * 0.03 + n * 0.08 + d * 0.0006);
	vec3 col = hsv2rgb(vec3(fract(0.75 + t * 0.02), 0.6, 0.06));
	col += hsv2rgb(vec3(hue, 0.9, 1.0)) * (0.04 + 0.05 * (n * 0.25 + 0.5)) * intensity;
	col += hsv2rgb(vec3(fract(hue + 0.5), 0.8, 1.0)) * fil * 0.12 * intensity;
	col += hsv2rgb(vec3(fract(hue + 0.3), 0.9, 1.0)) * dots * 0.3 * intensity;
	float v = smoothstep(0.35, 0.95, length(UV - 0.5) * 1.4);
	col = mix(col, hsv2rgb(vec3(fract(0.8 + t * 0.03), 0.8, 0.2)), v * 0.6);
	col += hsv2rgb(vec3(fract(t * 0.5), 1.0, 1.0)) * pulse * 0.35;
	COLOR = vec4(col, 1.0);
}
