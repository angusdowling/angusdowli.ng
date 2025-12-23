// ============================================================================
// NOISE FUNCTIONS
// ============================================================================

vec2 mod289(vec2 x) { 
  return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

vec3 mod289(vec3 x) { 
  return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

vec4 mod289(vec4 x) { 
  return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

vec3 permute(vec3 x) { 
  return mod289(((x * 34.0) + 1.0) * x); 
}

vec4 permute(vec4 x) { 
  return mod289(((x * 34.0) + 1.0) * x); 
}

vec4 taylorInvSqrt(vec4 r) { 
  return 1.79284291400159 - 0.85373472095314 * r; 
}

// 2D Simplex noise
float snoise(vec2 v) {
  const vec4 C = vec4(
    0.211324865405187,   // (3.0 - sqrt(3.0)) / 6.0
    0.366025403784439,   // 0.5 * (sqrt(3.0) - 1.0)
    -0.577350269189626,  // -1.0 + 2.0 * C.x
    0.024390243902439    // 1.0 / 41.0
  );
  
  vec2 i = floor(v + dot(v, C.yy));
  vec2 x0 = v - i + dot(i, C.xx);
  
  vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  
  i = mod289(i);
  vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
  
  vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
  m = m * m;
  m = m * m;
  
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  
  m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
  
  vec3 g;
  g.x = a0.x * x0.x + h.x * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  
  return 130.0 * dot(m, g);
}

// 2D Simplex noise with analytical gradient
// Returns vec3(noise, dNoise/dx, dNoise/dy) - nearly free derivative computation
vec3 snoiseGrad(vec2 v) {
  const vec4 C = vec4(
    0.211324865405187,   // (3.0 - sqrt(3.0)) / 6.0
    0.366025403784439,   // 0.5 * (sqrt(3.0) - 1.0)
    -0.577350269189626,  // -1.0 + 2.0 * C.x
    0.024390243902439    // 1.0 / 41.0
  );
  
  vec2 i = floor(v + dot(v, C.yy));
  vec2 x0 = v - i + dot(i, C.xx);
  
  vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  
  i = mod289(i);
  vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
  
  // Radial falloff from each simplex corner
  vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
  vec3 m2 = m * m;
  vec3 m4 = m2 * m2;
  
  // Gradient vectors
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  
  // Normalize gradients
  vec3 norm = 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
  vec3 g0 = vec3(a0.x * norm.x, h.x * norm.x, 0.0);
  vec3 g1 = vec3(a0.y * norm.y, h.y * norm.y, 0.0);
  vec3 g2 = vec3(a0.z * norm.z, h.z * norm.z, 0.0);
  
  // Noise value: sum of contributions from each corner
  vec3 gDotX = vec3(
    g0.x * x0.x + g0.y * x0.y,
    g1.x * x12.x + g1.y * x12.y,
    g2.x * x12.z + g2.y * x12.w
  );
  float noise = 130.0 * dot(m4 * norm, gDotX / norm);
  
  // Analytical gradient: d/dx of sum(m^4 * (g . x))
  // = sum(4 * m^3 * dm/dx * (g . x) + m^4 * g.x)
  // where dm/dx = -2x for each corner's distance
  vec2 dm0 = -8.0 * m2.x * m.x * x0;
  vec2 dm1 = -8.0 * m2.y * m.y * x12.xy;
  vec2 dm2 = -8.0 * m2.z * m.z * x12.zw;
  
  vec2 grad = vec2(0.0);
  grad += dm0 * gDotX.x + m4.x * g0.xy;
  grad += dm1 * gDotX.y + m4.y * g1.xy;
  grad += dm2 * gDotX.z + m4.z * g2.xy;
  grad *= 130.0;
  
  return vec3(noise, grad);
}

// 3D Simplex noise
float snoise3(vec3 v) {
  const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
  const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
  
  vec3 i = floor(v + dot(v, C.yyy));
  vec3 x0 = v - i + dot(i, C.xxx);
  
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min(g.xyz, l.zxy);
  vec3 i2 = max(g.xyz, l.zxy);
  
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy;
  vec3 x3 = x0 - D.yyy;
  
  i = mod289(i);
  vec4 p = permute(permute(permute(
    i.z + vec4(0.0, i1.z, i2.z, 1.0)) +
    i.y + vec4(0.0, i1.y, i2.y, 1.0)) +
    i.x + vec4(0.0, i1.x, i2.x, 1.0));
  
  float n_ = 0.142857142857;
  vec3 ns = n_ * D.wyz - D.xzx;
  
  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_);
  vec4 x = x_ * ns.x + ns.yyyy;
  vec4 y = y_ * ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);
  
  vec4 b0 = vec4(x.xy, y.xy);
  vec4 b1 = vec4(x.zw, y.zw);
  vec4 s0 = floor(b0) * 2.0 + 1.0;
  vec4 s1 = floor(b1) * 2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));
  
  vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
  vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
  
  vec3 p0 = vec3(a0.xy, h.x);
  vec3 p1 = vec3(a0.zw, h.y);
  vec3 p2 = vec3(a1.xy, h.z);
  vec3 p3 = vec3(a1.zw, h.w);
  
  vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  
  vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
  m = m * m;
  
  return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

