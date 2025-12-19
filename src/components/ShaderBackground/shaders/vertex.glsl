#version 300 es

// Full-screen quad vertex shader
// Positions are expected as clip-space coordinates (-1 to 1)

in vec2 a_position;

void main() {
  gl_Position = vec4(a_position, 0.0, 1.0);
}
