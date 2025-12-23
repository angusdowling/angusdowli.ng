// ============================================================================
// SIGNED DISTANCE FUNCTIONS
// ============================================================================

float sdSphere(vec3 p, float radius) {
  return length(p) - radius;
}

float sdBox(vec3 p, vec3 halfExtents) {
  vec3 q = abs(p) - halfExtents;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdPyramid(vec3 p, float height) {
  float m2 = height * height + 0.25;
  
  p.xz = abs(p.xz);
  p.xz = (p.z > p.x) ? p.zx : p.xz;
  p.xz -= 0.5;
  
  vec3 q = vec3(p.z, height * p.y - 0.5 * p.x, height * p.x + 0.5 * p.y);
  
  float s = max(-q.x, 0.0);
  float t = clamp((q.y - 0.5 * p.z) / (m2 + 0.25), 0.0, 1.0);
  
  float a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
  float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);
  float d2 = min(q.y, -q.x * m2 - q.y * 0.5) > 0.0 ? 0.0 : min(a, b);
  
  return sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -p.y));
}

float sdTorus(vec3 p, float ringRadius, float tubeRadius) {
  vec2 q = vec2(length(p.xz) - ringRadius, p.y);
  return length(q) - tubeRadius;
}

float sdOctahedron(vec3 p, float size) {
  p = abs(p);
  float m = p.x + p.y + p.z - size;
  
  vec3 q;
  if (3.0 * p.x < m) q = p.xyz;
  else if (3.0 * p.y < m) q = p.yzx;
  else if (3.0 * p.z < m) q = p.zxy;
  else return m * 0.57735027;
  
  float k = clamp(0.5 * (q.z - q.y + size), 0.0, size);
  return length(vec3(q.x, q.y - size + k, q.z - k));
}

float sdRoundBox(vec3 p, vec3 b, float r) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

// ============================================================================
// ROTATION MATRICES
// ============================================================================

mat3 rotateX(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat3(
    1.0, 0.0, 0.0,
    0.0, c, -s,
    0.0, s, c
  );
}

mat3 rotateY(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat3(
    c, 0.0, s,
    0.0, 1.0, 0.0,
    -s, 0.0, c
  );
}

mat3 rotateZ(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat3(
    c, -s, 0.0,
    s, c, 0.0,
    0.0, 0.0, 1.0
  );
}

