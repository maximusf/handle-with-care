// Backdrop behind the result screen.
// Takes whatever is drawn behind it (the level), removes some of its colour, then tints it.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float desaturation : hint_range(0.0, 1.0) = 0.0; // 0 = full colour, 1 = black and white
uniform vec4 tint_color : source_color = vec4(0.0, 0.0, 0.0, 0.0); // Alpha is how strong the tint is

void fragment() {
	vec3 level_color = texture(screen_texture, SCREEN_UV).rgb;
	float brightness = dot(level_color, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = mix(level_color, vec3(brightness), desaturation);
	COLOR = vec4(mix(desaturated, tint_color.rgb, tint_color.a), 1.0);
}
