shader_type canvas_item;

uniform sampler2D binaryDataTexture; // 2D texture for binary data
uniform int gridWidth;      // Number of cells horizontally and vertically

const int cellSize = 8;    // Cell size in pixels

void fragment() {
	vec2 totalGridSize = vec2(float(gridWidth) * float(cellSize));
	
	vec2 scaledUV = UV * float(gridWidth);
	
	ivec2 cellIndex = ivec2(floor(scaledUV));
	
	vec2 cellUV = fract(scaledUV);
	bool isInsideCell = all(greaterThanEqual(cellUV, vec2(0.0))) && all(lessThan(cellUV, vec2(1.0)));
	
	vec2 binaryDataUV = vec2(
		float(cellIndex.x) / float(gridWidth - 1),
		float(cellIndex.y) / float(gridWidth - 1)
	);
	
	float binaryValue = texture(binaryDataTexture, binaryDataUV).r;
	
    vec4 litColor = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 unlitColor = vec4(0.0, 0.0, 0.0, 1.0);
	
	COLOR = mix(unlitColor, litColor, binaryValue);
}
