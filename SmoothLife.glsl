#[compute]
#version 450

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout(set = 0, binding = 0, r8) restrict uniform readonly image2D inputImage;
layout(set = 0, binding = 1, r8) restrict uniform writeonly image2D outputImage;

ivec2 imageSize = imageSize(inputImage);

layout(set = 0, binding = 2) buffer SmoothLifeParameters {
    int innerCircleRadius;
    int outerCircleRadius;
    float birthInterval1;
    float birthInterval2;
    float deathInterval1;
    float deathInterval2;
    float alphaN;
    float alphaM;
    float rimWidth;
};

float sigmoid1(float x, float a) {
    return 1.0 / (exp(-(x - a) * 4.0 / alphaM));
}

float sigmoid2(float x, float a, float b) {
    return sigmoid1(x, a) * (1.0 - sigmoid1(x, b));
}

float sigmoidM(float x, float y, float m) {
    return x * (1.0 - sigmoid1(m, 0.5)) + y * sigmoid1(m, 0.5);
}

float cellState(float innerFilling, float outerFilling) {
    float a = sigmoidM(birthInterval1, deathInterval1, innerFilling);
    float b = sigmoidM(birthInterval2, deathInterval2, innerFilling);
    return sigmoid2(outerFilling, a, b);
}

float getCircleFilling(ivec2 cellPos, int radius) {
    float neighbouringCellCount = 0;
    float cellSum = 0;

    for (int x = -radius; x <= radius; x++) {
        for (int y = -radius; y <= radius; y++) {
            ivec2 pos = cellPos + ivec2(x, y);

            bool isCellInImage = all(greaterThanEqual(pos, ivec2(0, 0))) && all(lessThanEqual(pos, imageSize));

            if (!isCellInImage) continue;

            neighbouringCellCount += 1;

            float distance = sqrt(x * x + y * y);

            if (distance > radius) continue;

            vec4 cellColor = imageLoad(inputImage, pos);

            if (distance > radius + rimWidth / 2) {
                continue;
            }
            if (distance >= radius - rimWidth / 2) {
                cellColor *= (radius + rimWidth / 2 - distance) / rimWidth;
            }

            //float colorAverage = (cellColor.x + cellColor.y + cellColor.z) / 3;
            cellSum += cellColor.x;
        }
    }
    return cellSum / neighbouringCellCount;
}

void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);

    float innerFilling = getCircleFilling(pos, innerCircleRadius);
    float outerFilling = getCircleFilling(pos, outerCircleRadius);
    float newCellState = cellState(innerFilling, outerFilling);

    vec4 color = vec4(newCellState, newCellState, newCellState, 1.0);
    imageStore(outputImage, pos, color);
}
