RSRC                    RDShaderFile            ��������                                                  resource_local_to_scene    resource_name    bytecode_vertex    bytecode_fragment    bytecode_tesselation_control     bytecode_tesselation_evaluation    bytecode_compute    compile_error_vertex    compile_error_fragment "   compile_error_tesselation_control %   compile_error_tesselation_evaluation    compile_error_compute    script 
   _versions    base_error           local://RDShaderSPIRV_3ucki ;         local://RDShaderFile_pa605 �         RDShaderSPIRV          X	  Failed parse:
ERROR: 0:5: 'binding' : uniform/buffer blocks require layout(binding=X) 
ERROR: 1 compilation errors.  No code generated.




Stage 'compute' source code: 

1		#version 450
2		
3		layout(set = 0, binding = 0, rgba32f) uniform image2D input_texture;
4		
5		layout(std140) uniform ParameterBlock {
6		    float inner_radius;
7		    float outer_radius;
8		    float birth_interval1;
9		    float birth_interval2;
10		    float death_interval1;
11		    float death_interval2;
12		};
13		
14		ivec2 image_size = imageSize(input_texture);
15		
16		float circle_filling(ivec2 texel_position, int radius) {
17		    float max_cell_sum = 0.0;
18		    float cell_sum = 0.0;
19		
20		    for (int x = -radius; x <= radius; x++) {
21		        for (int y = -radius; y <= radius; y++) {
22		            bool is_point_in_circle = x * x + y * y <= radius * radius;
23		            if (!is_point_in_circle) {
24		                continue;
25		            }
26		
27		            ivec2 cell_position = texel_position + ivec2(x, y);
28		            bool is_cell_in_image = cell_position.x >= 0 && cell_position.x < image_size.x &&
29		                                    cell_position.y >= 0 && cell_position.y < image_size.y;
30		            if (!is_cell_in_image) {
31		                continue;
32		            }
33		
34		            vec4 texel_color = imageLoad(input_texture, cell_position);
35		            float color_average = (texel_color.x + texel_color.y + texel_color.z) / 3.0;
36		            cell_sum += color_average;
37		            max_cell_sum += 1.0;
38		        }
39		    }
40		
41		    return cell_sum / max_cell_sum;
42		}
43		
44		void main() {
45		    ivec2 texel_position = ivec2(gl_GlobalInvocationID.xy);
46		
47		    // Example: Compute the circle_filling value
48		    int inner_radius = 3;  // Adjust the radius as needed
49		    int outer_radius = 3 * inner_radius;  // Adjust the radius as needed
50		    float inner_value = circle_filling(texel_position, inner_radius);
51		    float outer_value = circle_filling(texel_position, outer_radius);
52		    float cell_value = (inner_value + outer_value) / 2;
53		
54		    // Example: Write the computed value back to the image
55		    vec4 color = vec4(cell_value, cell_value, cell_value, 1.0);
56		    imageStore(input_texture, texel_position, color);
57		}
58		
          RDShaderFile                                    RSRC