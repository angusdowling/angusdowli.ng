#version 300 es
precision highp float;

uniform vec2 iResolution;
uniform float iTime;
uniform vec4 iMouse;

out vec4 fragColor;

// Simplex noise functions
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                      -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy));
  vec2 x0 = v - i + dot(i, C.xx);
  vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod289(i);
  vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m; m = m*m;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
  vec3 g;
  g.x = a0.x * x0.x + h.x * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

// 3D Simplex noise
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise3(vec3 v) {
  const vec2 C = vec2(1.0/6.0, 1.0/3.0);
  const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
  vec3 i  = floor(v + dot(v, C.yyy));
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
    i.z + vec4(0.0, i1.z, i2.z, 1.0))
    + i.y + vec4(0.0, i1.y, i2.y, 1.0))
    + i.x + vec4(0.0, i1.x, i2.x, 1.0));
  float n_ = 0.142857142857;
  vec3 ns = n_ * D.wyz - D.xzx;
  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_);
  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);
  vec4 b0 = vec4(x.xy, y.xy);
  vec4 b1 = vec4(x.zw, y.zw);
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));
  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;
  vec3 p0 = vec3(a0.xy, h.x);
  vec3 p1 = vec3(a0.zw, h.y);
  vec3 p2 = vec3(a1.xy, h.z);
  vec3 p3 = vec3(a1.zw, h.w);
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
  p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

// Signed Distance Functions
float sdSphere(vec3 p, float r) {
  return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdPyramid(vec3 p, float h) {
  float m2 = h*h + 0.25;
  p.xz = abs(p.xz);
  p.xz = (p.z > p.x) ? p.zx : p.xz;
  p.xz -= 0.5;
  vec3 q = vec3(p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);
  float s = max(-q.x, 0.0);
  float t = clamp((q.y - 0.5*p.z) / (m2 + 0.25), 0.0, 1.0);
  float a = m2*(q.x + s)*(q.x + s) + q.y*q.y;
  float b = m2*(q.x + 0.5*t)*(q.x + 0.5*t) + (q.y - m2*t)*(q.y - m2*t);
  float d2 = min(q.y, -q.x*m2 - q.y*0.5) > 0.0 ? 0.0 : min(a, b);
  return sqrt((d2 + q.z*q.z) / m2) * sign(max(q.z, -p.y));
}

float sdTorus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

float sdOctahedron(vec3 p, float s) {
  p = abs(p);
  float m = p.x + p.y + p.z - s;
  vec3 q;
  if (3.0*p.x < m) q = p.xyz;
  else if (3.0*p.y < m) q = p.yzx;
  else if (3.0*p.z < m) q = p.zxy;
  else return m * 0.57735027;
  float k = clamp(0.5*(q.z - q.y + s), 0.0, s);
  return length(vec3(q.x, q.y - s + k, q.z - k));
}

// Rotation matrices
mat3 rotateY(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

mat3 rotateX(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// Shape morphing - only compute 2 active shapes
float getShapeSDF(vec3 p, float morphTime) {
  float shapeHoldTime = 4.0;
  float transitionTime = 1.0;
  
  float segmentTime = shapeHoldTime + transitionTime;
  float cycleTime = segmentTime * 5.0;
  float t = mod(morphTime, cycleTime);
  
  int currentShape = int(floor(t / segmentTime));
  float segmentProgress = mod(t, segmentTime);
  
  float morphProgress = 0.0;
  if (segmentProgress > shapeHoldTime) {
    morphProgress = (segmentProgress - shapeHoldTime) / transitionTime;
  }
  
  float ease = morphProgress * morphProgress * (3.0 - 2.0 * morphProgress);
  float shapeScale = 1.0;
  
  float d1, d2;
  
  if (currentShape == 0) {
    d1 = sdPyramid(p + vec3(0.0, 0.35 * shapeScale, 0.0), 1.0 * shapeScale) * 0.7;
    d2 = sdSphere(p, 0.65 * shapeScale);
  } else if (currentShape == 1) {
    d1 = sdSphere(p, 0.65 * shapeScale);
    d2 = sdBox(p, vec3(0.5 * shapeScale));
  } else if (currentShape == 2) {
    d1 = sdBox(p, vec3(0.5 * shapeScale));
    d2 = sdOctahedron(p, 0.8 * shapeScale);
  } else if (currentShape == 3) {
    d1 = sdOctahedron(p, 0.8 * shapeScale);
    d2 = sdTorus(p, vec2(0.5 * shapeScale, 0.22 * shapeScale));
  } else {
    d1 = sdTorus(p, vec2(0.5 * shapeScale, 0.22 * shapeScale));
    d2 = sdPyramid(p + vec3(0.0, 0.35 * shapeScale, 0.0), 1.0 * shapeScale) * 0.7;
  }
  
  return mix(d1, d2, ease);
}

float rayMarch(vec3 ro, vec3 rd, float morphTime) {
  float t = 0.0;
  for (int i = 0; i < 64; i++) {
    vec3 p = ro + rd * t;
    float d = getShapeSDF(p, morphTime);
    if (d < 0.001) return t;
    if (t > 10.0) break;
    t += d * 0.8;
  }
  return -1.0;
}

vec3 getNormal(vec3 p, float morphTime) {
  float e = 0.001;
  return normalize(vec3(
    getShapeSDF(p + vec3(e, 0, 0), morphTime) - getShapeSDF(p - vec3(e, 0, 0), morphTime),
    getShapeSDF(p + vec3(0, e, 0), morphTime) - getShapeSDF(p - vec3(0, e, 0), morphTime),
    getShapeSDF(p + vec3(0, 0, e), morphTime) - getShapeSDF(p - vec3(0, 0, e), morphTime)
  ));
}

float waveHeight(vec2 xz, float t) {
  float h = 0.0;
  float waveStrength = 0.75;
  h += waveStrength * 0.40 * sin(1.25 * xz.x + 1.10 * t);
  h += waveStrength * 0.32 * sin(1.05 * xz.y - 1.35 * t + 1.2);
  h += waveStrength * 0.22 * sin(0.85 * (xz.x + xz.y) + 0.90 * t);
  h += waveStrength * 0.15 * sin(1.90 * length(xz * vec2(0.9, 1.1)) - 1.10 * t);
  return h;
}

vec3 heightNormal(vec2 xz, float t) {
  float e = 0.01;
  float h  = waveHeight(xz, t);
  float hx = waveHeight(xz + vec2(e, 0.0), t);
  float hz = waveHeight(xz + vec2(0.0, e), t);
  vec3 dx = vec3(e, hx - h, 0.0);
  vec3 dz = vec3(0.0, hz - h, e);
  return normalize(cross(dz, dx));
}

float distToLine(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

vec2 getDotPosition(vec2 cellCoord, float scale, vec2 mouseWorld, float pushRadius, float pushStrength) {
  vec2 dotCenter = (cellCoord + 0.5) / scale;
  vec2 toMouse = dotCenter - mouseWorld;
  float distToMouse = length(toMouse);
  
  if (distToMouse < pushRadius && distToMouse > 0.001) {
    vec2 pushDir = normalize(toMouse);
    float falloff = 1.0 - distToMouse / pushRadius;
    float pushAmount = pushStrength * falloff * falloff * falloff;
    dotCenter += pushDir * pushAmount;
  }
  return dotCenter;
}

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Letter "A" pattern
const vec2 LETTER_A_DIRS[32] = vec2[32](
  vec2(1.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 0.0),
  vec2(-0.5, 1.0), vec2(-0.5, 1.0),
  vec2(-1.0, 0.0),
  vec2(0.5, 1.0), vec2(0.5, 1.0),
  vec2(0.5, -1.0), vec2(0.5, -1.0), vec2(0.5, -1.0), vec2(0.5, -1.0),
  vec2(1.0, 0.0), vec2(1.0, 0.0),
  vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0),
  vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0),
  vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0),
  vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0)
);

vec2 getLetterADirection(int step) {
  int pos = step - (step / 32) * 32;
  return LETTER_A_DIRS[pos];
}

vec2 getPatternDirection(int step, int shapeType) {
  return getLetterADirection(step);
}

float drawBranch(vec2 xz, float scale, vec2 mouseWorld, float pushRadius, float pushStrength, 
                 vec2 originCell, float branchSeed, float branchPhase, int patternType) {
  float result = 0.0;
  float lineWidth = 0.006;
  float patternScale = 1.67;
  
  int maxSegments = 32;
  float windowSize = float(maxSegments) + 20.0;
  
  float totalTravel = float(maxSegments) + windowSize;
  float headPosition = branchPhase * totalTravel;
  float tailPosition = headPosition - windowSize;
  
  int startSeg = int(max(0.0, tailPosition - 2.0));
  int endSeg = int(min(float(maxSegments), headPosition + 2.0));
  
  vec2 originWorld = (originCell + 0.5) / scale;
  float maxExtent = float(maxSegments) * patternScale / scale;
  if (length(xz - originWorld) > maxExtent + 0.5) {
    return 0.0;
  }
  
  vec2 cell = originCell;
  for (int i = 0; i < 35; i++) {
    if (i >= startSeg) break;
    cell = cell + getPatternDirection(i, patternType) * patternScale;
  }
  
  for (int i = 0; i < 35; i++) {
    int segIdx = startSeg + i;
    if (segIdx >= endSeg) break;
    
    vec2 dir = getPatternDirection(segIdx, patternType) * patternScale;
    vec2 nextCell = cell + dir;
    
    vec2 dotA = getDotPosition(cell, scale, mouseWorld, pushRadius, pushStrength);
    vec2 dotB = getDotPosition(nextCell, scale, mouseWorld, pushRadius, pushStrength);
    
    float fSegIdx = float(segIdx);
    float fadeIn = smoothstep(0.0, 2.0, headPosition - fSegIdx);
    float fadeOut = smoothstep(0.0, 2.0, fSegIdx - tailPosition);
    float visibility = fadeIn * fadeOut;
    
    if (visibility > 0.01) {
      float d = distToLine(xz, dotA, dotB);
      float line = 1.0 - smoothstep(lineWidth * 0.5, lineWidth, d);
      result = max(result, line * visibility * 0.35);
    }
    
    cell = nextCell;
  }
  
  return result;
}

float dotConnections(vec2 xz, float scale, vec2 mouseWorld, float pushRadius, float pushStrength, float time) {
  float result = 0.0;
  
  float cycleDuration = 10.0;
  float patternScale = 1.0;
  
  float branchTime = time;
  float cycleIndex = floor(branchTime / cycleDuration);
  float branchPhase = fract(branchTime / cycleDuration);
  float seed = cycleIndex * 17.3;
  
  vec2 center = vec2(-4.0, 9.0);
  vec2 startOffset = vec2(-3.0, -4.0);
  vec2 originCell = center + startOffset * patternScale;
  
  result = max(result, drawBranch(xz, scale, mouseWorld, pushRadius, pushStrength, 
                                   originCell, seed, branchPhase, 0));
  
  return result;
}

float dotGridDisplaced(vec2 xz, float scale, float dotSize, vec2 mouseWorld, float pushRadius, float pushStrength, float time) {
  vec2 g = xz * scale;
  vec2 cell = floor(g);
  float stretch = 1.0;
  float result = 0.0;
  
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      vec2 neighborCell = cell + vec2(float(dx), float(dy));
      vec2 dotCenter = getDotPosition(neighborCell, scale, mouseWorld, pushRadius, pushStrength);
      
      vec2 delta = (xz - dotCenter) * scale;
      vec2 hStretch = vec2(delta.x / stretch, delta.y);
      vec2 vStretch = vec2(delta.x, delta.y / stretch);
      float hDist = length(hStretch);
      float vDist = length(vStretch);
      float distToDot = min(hDist, vDist);
      
      float baseSize = 0.011;
      float sizeFactor = stretch > 1.5 ? 0.25 : 1.0;
      float innerSize = dotSize * baseSize * sizeFactor;
      float outerSize = innerSize + baseSize;
      
      result = max(result, 1.0 - smoothstep(innerSize, outerSize, distToDot));
    }
  }
  return result;
}

void main() {
  vec2 fragCoord = gl_FragCoord.xy;
  vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
  float t = iTime;
  vec2 mouseUV = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;

  // Floor camera setup
  vec3 floorRo = vec3(0.0, 14.0, 0.5);
  vec3 ta = vec3(0.0, 0.0, 1.0);
  vec3 ww = normalize(ta - floorRo);
  vec3 uu = normalize(cross(vec3(0.0, 1.0, 0.0), ww));
  vec3 vv = cross(ww, uu);
  vec3 floorRd = normalize(uu * uv.x + vv * uv.y + ww * 1.25);

  // Intersect ray with heightfield
  float T = 0.0;
  if (abs(floorRd.y) > 1e-4) {
    T = (0.0 - floorRo.y) / floorRd.y;
    T = max(T, 0.0);
  }
  for (int i = 0; i < 10; i++) {
    vec3 p = floorRo + floorRd * T;
    float h = waveHeight(p.xz, t);
    float dy = (h - p.y);
    T += dy / floorRd.y;
  }
  vec3 floorP = floorRo + floorRd * T;

  float intensity = 0.0;
  bool hitFloor = (T >= 0.0 && T <= 50.0 && floorRd.y <= -0.02);
  
  if (hitFloor) {
    float h = waveHeight(floorP.xz, t);
    floorP.y = h;

    vec3 mouseRd = normalize(uu * mouseUV.x + vv * mouseUV.y + ww * 1.25);
    float mouseT = -floorRo.y / mouseRd.y;
    vec2 mouseWorld = floorRo.xz + mouseRd.xz * mouseT;

    float scale = 12.0;
    float dotSize = 7.0;
    float pushRadius = 0.8;
    float pushStrength = 0.3;
    float dots = dotGridDisplaced(floorP.xz, scale, dotSize, mouseWorld, pushRadius, pushStrength, t);
    float connections = dotConnections(floorP.xz, scale, mouseWorld, pushRadius, pushStrength, t);
    float combined = max(dots, connections);

    vec3 n = heightNormal(floorP.xz, t);
    vec3 l = normalize(vec3(-0.35, 0.75, -0.25));
    float diff = clamp(dot(n, l), 0.0, 1.0);
    float slope = 1.0 - n.y;
    float ridge = smoothstep(0.10, 0.55, slope);
    float distFade = exp(-0.045 * T);

    intensity = combined * (0.35 + 0.65 * diff);
    intensity *= (0.70 + 0.80 * ridge);
    intensity *= distFade;
  }

  // 3D Shape
  float rotationSpeed = t * 0.25;
  vec2 shapeCenter = vec2(0.0, 0.0);
  
  vec3 shapeCamPos = vec3(0.0, 0.0, 3.0);
  vec3 shapeCamDir = normalize(vec3(uv - shapeCenter, -1.5));
  
  mat3 rotY = rotateY(rotationSpeed);
  mat3 rotX = rotateX(t * 0.15);
  mat3 rot = rotY * rotX;
  
  vec3 ro = shapeCamPos;
  vec3 rd = shapeCamDir;
  float morphTime = t * 0.5;
  float shapeDist = rayMarch(ro, rd, morphTime);
  
  float densityField = 0.0;
  
  if (shapeDist > 0.0) {
    vec3 hitPos = ro + rd * shapeDist;
    vec3 normal = getNormal(hitPos, morphTime);
    vec3 rotatedPos = rot * hitPos;
    
    float noiseScale = 0.5;
    float noiseTime = t * 0.2;
    
    float n1 = snoise3(rotatedPos * noiseScale + vec3(noiseTime, 0.0, noiseTime * 0.7));
    float n2 = snoise3(rotatedPos * noiseScale * 2.0 + vec3(-noiseTime * 0.8, noiseTime * 0.5, 0.0)) * 0.5;
    float n3 = snoise3(rotatedPos * noiseScale * 4.0 + vec3(0.0, -noiseTime * 0.6, noiseTime * 0.4)) * 0.25;
    
    float noisePattern = n1 + n2 + n3;
    densityField = smoothstep(-0.5, 1.2, noisePattern);
    
    float fresnel = 1.0 - abs(dot(normal, -rd));
    fresnel = pow(fresnel, 1.5);
    densityField = mix(densityField, densityField * 1.3, fresnel * 0.5);
    
    float edgeSoftness = smoothstep(0.0, 0.15, abs(getShapeSDF(hitPos, morphTime)));
    densityField *= 1.0 - edgeSoftness * 0.3;
    
    float cloudMouseDist = length(uv - mouseUV);
    float cloudRepelRadius = 0.35;
    float cloudRepelStrength = 0.20;
    if (cloudMouseDist < cloudRepelRadius) {
      float repelFalloff = 1.0 - cloudMouseDist / cloudRepelRadius;
      repelFalloff = repelFalloff * repelFalloff * repelFalloff;
      densityField *= 1.0 - repelFalloff * cloudRepelStrength;
    }
  }
  
  // Grain effect
  float shimmer = 0.015;
  float grainTime = t * 0.08;
  
  float grainMouseDist = length(uv - mouseUV);
  float grainMouseInfluence = smoothstep(0.4, 0.0, grainMouseDist) * 0.02;
  
  vec2 grainOffset = vec2(
    snoise(fragCoord * 0.01 + grainTime * 0.05),
    snoise(fragCoord * 0.01 + 100.0 + grainTime * 0.04)
  ) * (shimmer + grainMouseInfluence);
  
  if (grainMouseDist < 0.4 && grainMouseDist > 0.001) {
    vec2 grainPushDir = normalize(uv - mouseUV);
    grainOffset += grainPushDir * grainMouseInfluence * 50.0;
  }
  
  vec2 grainCoord = fragCoord + grainOffset;
  
  float grain1 = fract(sin(dot(grainCoord, vec2(12.9898, 78.233))) * 43758.5453);
  float grain2 = fract(sin(dot(grainCoord * 0.5 + 50.0, vec2(63.7264, 10.873))) * 28947.2934);
  float grain3 = fract(sin(dot(grainCoord * 2.0 + 100.0, vec2(91.2834, 45.164))) * 61532.8372);
  
  float grain = grain1 * 0.5 + grain2 * 0.3 + grain3 * 0.2;
  
  float threshold = 1.0 - densityField * 0.75;
  float stipple = smoothstep(threshold, threshold + 0.12, grain);
  
  float grainIntensity = stipple * densityField;
  
  // Final composition
  float baseGray = 0.96;
  float grainDarkness = 0.32;
  float grayValue = baseGray - grainIntensity * grainDarkness;
  
  vec3 gradient = vec3(grayValue);
  vec3 dotColor = vec3(0.0);
  vec3 col = mix(gradient, dotColor, intensity);
  
  fragColor = vec4(col, 1.0);
}

