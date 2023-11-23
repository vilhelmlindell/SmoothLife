#[compute]
#version 450

layout(set = 0, binding = 0, rgba32f) uniform image2D input_texture;

layout(set = 0, binding = 1) uniform SimulationParameters {
    float inner_radius;
    float outer_radius;
    float birth_interval_1;
    float birth_interval_2;
    float death_interval_1;
    float death_interval_2;
    float alpha_n;
    float alpha_m;
};

ivec2 image_size = imageSize(input_texture);

float sigmoid_1(float x, float a) {
    return 1.0 / (exp(-(x - a) * 4.0 / alpha_m));
}

float sigmoid_2(float x, float a, float b) {
    return sigmoid_1(x, a) * (1.0 - sigmoid_1(x, b));
}

float sigmoid_m(float x, float y, float m) {
    return x * (1.0 - sigmoid_1(m, 0.5)) + y * sigmoid_1(m, 0.5);
}

float cell_state(float inner_filling, float outer_filling) {
    float a = sigmoid_m(birth_interval_1, death_interval_1, inner_filling);
    float b = sigmoid_m(birth_interval_2, death_interval_2, inner_filling);
    return sigmoid_2(outer_filling, a, b);
}

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
            bool is_cell_in_image = all(greaterThanEqual(cell_position, ivec2(0)) ) &&
                                    all(lessThan(cell_position, image_size));
            if (!is_cell_in_image) {
                continue;
            }

            vec4 texel_color = imageLoad(input_texture, cell_position);
            float color_average = dot(texel_color.rgb, vec3(1.0 / 3.0));
            cell_sum += color_average;
            max_cell_sum += 1.0;
        }
    }

    return cell_sum / max_cell_sum;
}

void main() {
    ivec2 texel_position = ivec2(gl_GlobalInvocationID.xy);

    // Example: Compute the circle_filling
    float inner_filling = circle_filling(texel_position, 3);
    float outer_filling = circle_filling(texel_position, 9);
    float current_cell_state = cell_state(inner_filling, outer_filling);

    // Example: Write the computed value back to the image
    vec4 color = vec4(current_cell_state);
    imageStore(input_texture, texel_position, color);
}
