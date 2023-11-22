#[compute]
#version 450

layout(set = 0, binding = 0, rgba32f) uniform image2D input_texture;

layout(std140) uniform ParameterBlock {
    float inner_radius;
    float outer_radius;
    float birth_interval1;
    float birth_interval2;
    float death_interval1;
    float death_interval2;
};

ivec2 image_size = imageSize(input_texture);

float circle_filling(ivec2 texel_position, int radius) {
    float max_cell_sum = 0.0;
    float cell_sum = 0.0;

    for (int x = -radius; x <= radius; x++) {
        for (int y = -radius; y <= radius; y++) {
            bool is_point_in_circle = x * x + y * y <= radius * radius;
            if (!is_point_in_circle) {
                continue;
            }

            ivec2 cell_position = texel_position + ivec2(x, y);
            bool is_cell_in_image = cell_position.x >= 0 && cell_position.x < image_size.x &&
                                    cell_position.y >= 0 && cell_position.y < image_size.y;
            if (!is_cell_in_image) {
                continue;
            }

            vec4 texel_color = imageLoad(input_texture, cell_position);
            float color_average = (texel_color.x + texel_color.y + texel_color.z) / 3.0;
            cell_sum += color_average;
            max_cell_sum += 1.0;
        }
    }

    return cell_sum / max_cell_sum;
}

void main() {
    ivec2 texel_position = ivec2(gl_GlobalInvocationID.xy);

    // Example: Compute the circle_filling value
    int inner_radius = 3;  // Adjust the radius as needed
    int outer_radius = 3 * inner_radius;  // Adjust the radius as needed
    float inner_value = circle_filling(texel_position, inner_radius);
    float outer_value = circle_filling(texel_position, outer_radius);
    float cell_value = (inner_value + outer_value) / 2;

    // Example: Write the computed value back to the image
    vec4 color = vec4(cell_value, cell_value, cell_value, 1.0);
    imageStore(input_texture, texel_position, color);
}