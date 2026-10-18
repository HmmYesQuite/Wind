shader_type canvas_item;

uniform float blurSize = 0.0;

varying vec4 modulateColor;

void vertex() {
	modulateColor = COLOR;
}

void fragment() {
	if (blurSize <= 0.0) {
		COLOR = texture(TEXTURE, UV) * modulateColor;
	} else {
		vec2 stepSize = TEXTURE_PIXEL_SIZE * blurSize * 0.5;
		vec4 total = vec4(0.0);
		for (int x = -2; x <= 2; x++) {
			for (int y = -2; y <= 2; y++) {
				total += texture(TEXTURE, UV + vec2(float(x), float(y)) * stepSize);
			}
		}
		COLOR = total / 25.0 * modulateColor;
	}
}
