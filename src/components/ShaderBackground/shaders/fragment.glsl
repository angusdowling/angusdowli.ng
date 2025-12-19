#version 300 es
precision highp float;

// ============================================================================
// UNIFORMS
// ============================================================================

uniform vec2 iResolution;
uniform float iTime;
uniform vec4 iMouse;

out vec4 fragColor;

// ============================================================================
// CONSTANTS
// ============================================================================

// Visual tuning
const float DOT_GRID_SCALE = 12.0;
const float DOT_SIZE = 7.0;
const float MOUSE_PUSH_RADIUS = 0.8;
const float MOUSE_PUSH_STRENGTH = 0.3;

// Wave parameters
const float WAVE_STRENGTH = 0.75;

// Shape morphing timing
const float SHAPE_HOLD_TIME = 4.0;
const float SHAPE_TRANSITION_TIME = 1.0;
const int SHAPE_COUNT = 5;

// Camera
const vec3 FLOOR_CAMERA_POSITION = vec3(0.0, 14.0, 0.5);
const vec3 FLOOR_CAMERA_TARGET = vec3(0.0, 0.0, 1.0);
const float FLOOR_CAMERA_FOV = 1.25;

const vec3 SHAPE_CAMERA_POSITION = vec3(0.0, 0.0, 3.0);
const float SHAPE_CAMERA_FOV = 1.5;

// Rendering
const int RAY_MARCH_STEPS = 64;
const float RAY_MARCH_THRESHOLD = 0.001;
const float RAY_MARCH_MAX_DIST = 10.0;

// Colors
const float BACKGROUND_GRAY = 0.96;
const float GRAIN_DARKNESS = 0.32;

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

// ============================================================================
// SHAPE MORPHING
// ============================================================================

// Calculates SDF for current morphing shape based on time
float getMorphedShapeSDF(vec3 p, float time) {
  float segmentDuration = SHAPE_HOLD_TIME + SHAPE_TRANSITION_TIME;
  float cycleDuration = segmentDuration * float(SHAPE_COUNT);
  float cycleTime = mod(time, cycleDuration);
  
  int currentShape = int(floor(cycleTime / segmentDuration));
  float segmentProgress = mod(cycleTime, segmentDuration);
  
  // Calculate morph progress (0 during hold, 0-1 during transition)
  float morphProgress = 0.0;
  if (segmentProgress > SHAPE_HOLD_TIME) {
    morphProgress = (segmentProgress - SHAPE_HOLD_TIME) / SHAPE_TRANSITION_TIME;
  }
  
  // Smooth easing
  float ease = morphProgress * morphProgress * (3.0 - 2.0 * morphProgress);
  
  // Get distances to current and next shapes
  float d1, d2;
  
  if (currentShape == 0) {
    d1 = sdPyramid(p + vec3(0.0, 0.35, 0.0), 1.0) * 0.7;
    d2 = sdSphere(p, 0.65);
  } else if (currentShape == 1) {
    d1 = sdSphere(p, 0.65);
    d2 = sdBox(p, vec3(0.5));
  } else if (currentShape == 2) {
    d1 = sdBox(p, vec3(0.5));
    d2 = sdOctahedron(p, 0.8);
  } else if (currentShape == 3) {
    d1 = sdOctahedron(p, 0.8);
    d2 = sdTorus(p, 0.5, 0.22);
  } else {
    d1 = sdTorus(p, 0.5, 0.22);
    d2 = sdPyramid(p + vec3(0.0, 0.35, 0.0), 1.0) * 0.7;
  }
  
  return mix(d1, d2, ease);
}

// ============================================================================
// RAY MARCHING
// ============================================================================

float rayMarch(vec3 rayOrigin, vec3 rayDirection, float morphTime) {
  float totalDistance = 0.0;
  
  for (int stepIndex = 0; stepIndex < RAY_MARCH_STEPS; stepIndex++) {
    vec3 currentPoint = rayOrigin + rayDirection * totalDistance;
    float distanceToSurface = getMorphedShapeSDF(currentPoint, morphTime);
    
    if (distanceToSurface < RAY_MARCH_THRESHOLD) {
      return totalDistance;
    }
    if (totalDistance > RAY_MARCH_MAX_DIST) {
      break;
    }
    
    totalDistance += distanceToSurface * 0.8;
  }
  
  return -1.0;
}

vec3 calculateNormal(vec3 surfacePoint, float morphTime) {
  const float sampleOffset = 0.001;
  float gradientX = getMorphedShapeSDF(surfacePoint + vec3(sampleOffset, 0.0, 0.0), morphTime) - 
                    getMorphedShapeSDF(surfacePoint - vec3(sampleOffset, 0.0, 0.0), morphTime);
  float gradientY = getMorphedShapeSDF(surfacePoint + vec3(0.0, sampleOffset, 0.0), morphTime) - 
                    getMorphedShapeSDF(surfacePoint - vec3(0.0, sampleOffset, 0.0), morphTime);
  float gradientZ = getMorphedShapeSDF(surfacePoint + vec3(0.0, 0.0, sampleOffset), morphTime) - 
                    getMorphedShapeSDF(surfacePoint - vec3(0.0, 0.0, sampleOffset), morphTime);
  return normalize(vec3(gradientX, gradientY, gradientZ));
}

// ============================================================================
// OCEAN WAVES
// ============================================================================

float calculateWaveHeight(vec2 position, float time) {
  float height = 0.0;
  height += WAVE_STRENGTH * 0.40 * sin(1.25 * position.x + 1.10 * time);
  height += WAVE_STRENGTH * 0.32 * sin(1.05 * position.y - 1.35 * time + 1.2);
  height += WAVE_STRENGTH * 0.22 * sin(0.85 * (position.x + position.y) + 0.90 * time);
  height += WAVE_STRENGTH * 0.15 * sin(1.90 * length(position * vec2(0.9, 1.1)) - 1.10 * time);
  return height;
}

vec3 calculateWaveNormal(vec2 position, float time) {
  const float sampleOffset = 0.01;
  float heightCenter = calculateWaveHeight(position, time);
  float heightX = calculateWaveHeight(position + vec2(sampleOffset, 0.0), time);
  float heightZ = calculateWaveHeight(position + vec2(0.0, sampleOffset), time);
  
  vec3 tangentX = vec3(sampleOffset, heightX - heightCenter, 0.0);
  vec3 tangentZ = vec3(0.0, heightZ - heightCenter, sampleOffset);
  
  return normalize(cross(tangentZ, tangentX));
}

// ============================================================================
// DOT GRID SYSTEM
// ============================================================================

// Calculate dot position with mouse repulsion
vec2 getDotWorldPosition(vec2 cellCoord, float gridScale, vec2 mouseWorldPos) {
  vec2 dotPosition = (cellCoord + 0.5) / gridScale;
  vec2 vectorToMouse = dotPosition - mouseWorldPos;
  float distanceToMouse = length(vectorToMouse);
  
  if (distanceToMouse < MOUSE_PUSH_RADIUS && distanceToMouse > 0.001) {
    vec2 repelDirection = normalize(vectorToMouse);
    float falloffFactor = 1.0 - distanceToMouse / MOUSE_PUSH_RADIUS;
    float repelAmount = MOUSE_PUSH_STRENGTH * falloffFactor * falloffFactor * falloffFactor;
    dotPosition += repelDirection * repelAmount;
  }
  
  return dotPosition;
}

// Distance from point to line segment
float distanceToLineSegment(vec2 point, vec2 lineStart, vec2 lineEnd) {
  vec2 pa = point - lineStart;
  vec2 ba = lineEnd - lineStart;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

// Render dot grid with mouse interaction
float renderDotGrid(vec2 worldPosition, float gridScale, vec2 mouseWorldPos) {
  vec2 gridPosition = worldPosition * gridScale;
  vec2 currentCell = floor(gridPosition);
  float outputIntensity = 0.0;
  
  // Check neighboring cells for dots
  for (int offsetX = -1; offsetX <= 1; offsetX++) {
    for (int offsetY = -1; offsetY <= 1; offsetY++) {
      vec2 neighborCell = currentCell + vec2(float(offsetX), float(offsetY));
      vec2 dotCenter = getDotWorldPosition(neighborCell, gridScale, mouseWorldPos);
      
      vec2 toDot = (worldPosition - dotCenter) * gridScale;
      float distanceToDot = min(length(vec2(toDot.x, toDot.y)), length(toDot));
      
      float innerRadius = DOT_SIZE * 0.011;
      float outerRadius = innerRadius + 0.011;
      
      outputIntensity = max(outputIntensity, 1.0 - smoothstep(innerRadius, outerRadius, distanceToDot));
    }
  }
  
  return outputIntensity;
}

// ============================================================================
// LETTER "A" PATTERN
// ============================================================================

const vec2 LETTER_A_PATH[32] = vec2[32](
  // Bottom horizontal stroke
  vec2(1.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 0.0),
  // Left leg going up
  vec2(-0.5, 1.0), vec2(-0.5, 1.0),
  // Crossbar left
  vec2(-1.0, 0.0),
  // Continue up left
  vec2(0.5, 1.0), vec2(0.5, 1.0),
  // Down to crossbar
  vec2(0.5, -1.0), vec2(0.5, -1.0), vec2(0.5, -1.0), vec2(0.5, -1.0),
  // Crossbar right
  vec2(1.0, 0.0), vec2(1.0, 0.0),
  // Right leg going up
  vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0),
  vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0),
  // Right leg going down
  vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0),
  vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0)
);

vec2 getLetterDirection(int step) {
  return LETTER_A_PATH[step - (step / 32) * 32];
}

// Render animated letter path
float renderLetterPath(vec2 worldPosition, float gridScale, vec2 mouseWorldPos, float time) {
  const float LINE_WIDTH = 0.006;
  const float LETTER_SCALE = 1.67;
  const float CYCLE_DURATION = 10.0;
  const int MAX_SEGMENTS = 32;
  const float VISIBLE_WINDOW = float(MAX_SEGMENTS) + 20.0;
  
  float cycleProgress = fract(time / CYCLE_DURATION);
  float totalTravelDistance = float(MAX_SEGMENTS) + VISIBLE_WINDOW;
  float animationHead = cycleProgress * totalTravelDistance;
  float animationTail = animationHead - VISIBLE_WINDOW;
  
  // Starting position for the letter
  vec2 startingCell = vec2(-4.0, 9.0) + vec2(-3.0, -4.0) * 1.0;
  vec2 startingWorldPos = (startingCell + 0.5) / gridScale;
  
  // Early exit if too far from letter
  float maxLetterExtent = float(MAX_SEGMENTS) * LETTER_SCALE / gridScale;
  if (length(worldPosition - startingWorldPos) > maxLetterExtent + 0.5) {
    return 0.0;
  }
  
  float outputIntensity = 0.0;
  int firstVisibleSegment = int(max(0.0, animationTail - 2.0));
  int lastVisibleSegment = int(min(float(MAX_SEGMENTS), animationHead + 2.0));
  
  // Advance to start segment
  vec2 currentCell = startingCell;
  for (int segmentIndex = 0; segmentIndex < firstVisibleSegment && segmentIndex < 35; segmentIndex++) {
    currentCell += getLetterDirection(segmentIndex) * LETTER_SCALE;
  }
  
  // Draw visible segments
  for (int loopIndex = 0; loopIndex < 35; loopIndex++) {
    int segmentIndex = firstVisibleSegment + loopIndex;
    if (segmentIndex >= lastVisibleSegment) break;
    
    vec2 segmentDirection = getLetterDirection(segmentIndex) * LETTER_SCALE;
    vec2 nextCell = currentCell + segmentDirection;
    
    vec2 segmentStart = getDotWorldPosition(currentCell, gridScale, mouseWorldPos);
    vec2 segmentEnd = getDotWorldPosition(nextCell, gridScale, mouseWorldPos);
    
    // Calculate visibility with fade in/out
    float segmentPosition = float(segmentIndex);
    float fadeInAmount = smoothstep(0.0, 2.0, animationHead - segmentPosition);
    float fadeOutAmount = smoothstep(0.0, 2.0, segmentPosition - animationTail);
    float segmentVisibility = fadeInAmount * fadeOutAmount;
    
    if (segmentVisibility > 0.01) {
      float distanceToLine = distanceToLineSegment(worldPosition, segmentStart, segmentEnd);
      float lineIntensity = 1.0 - smoothstep(LINE_WIDTH * 0.5, LINE_WIDTH, distanceToLine);
      outputIntensity = max(outputIntensity, lineIntensity * segmentVisibility * 0.35);
    }
    
    currentCell = nextCell;
  }
  
  return outputIntensity;
}

// ============================================================================
// FLOOR RENDERING
// ============================================================================

struct FloorHit {
  bool hit;
  vec3 position;
  float distance;
};

FloorHit traceFloor(vec3 rayOrigin, vec3 rayDirection, float time) {
  FloorHit result;
  result.hit = false;
  result.distance = 0.0;
  
  // Check if ray points toward floor
  if (rayDirection.y > -0.02) {
    return result;
  }
  
  // Initial intersection with y=0 plane
  float rayDistance = -rayOrigin.y / rayDirection.y;
  if (rayDistance < 0.0 || rayDistance > 50.0) {
    return result;
  }
  
  // Refine intersection with wave heightfield
  for (int i = 0; i < 10; i++) {
    vec3 surfacePoint = rayOrigin + rayDirection * rayDistance;
    float waveHeight = calculateWaveHeight(surfacePoint.xz, time);
    float heightDelta = waveHeight - surfacePoint.y;
    rayDistance += heightDelta / rayDirection.y;
  }
  
  result.hit = true;
  result.position = rayOrigin + rayDirection * rayDistance;
  result.position.y = calculateWaveHeight(result.position.xz, time);
  result.distance = rayDistance;
  
  return result;
}

float calculateFloorIntensity(FloorHit floorHit, vec2 mouseWorldPos, float time) {
  float dotPattern = renderDotGrid(floorHit.position.xz, DOT_GRID_SCALE, mouseWorldPos);
  float letterPattern = renderLetterPath(floorHit.position.xz, DOT_GRID_SCALE, mouseWorldPos, time);
  float combinedPattern = max(dotPattern, letterPattern);
  
  // Lighting
  vec3 surfaceNormal = calculateWaveNormal(floorHit.position.xz, time);
  vec3 lightDirection = normalize(vec3(-0.35, 0.75, -0.25));
  float diffuseLight = clamp(dot(surfaceNormal, lightDirection), 0.0, 1.0);
  
  // Ridge highlighting
  float slopeAmount = 1.0 - surfaceNormal.y;
  float ridgeHighlight = smoothstep(0.10, 0.55, slopeAmount);
  
  // Distance fade
  float distanceFade = exp(-0.045 * floorHit.distance);
  
  float outputIntensity = combinedPattern * (0.35 + 0.65 * diffuseLight);
  outputIntensity *= (0.70 + 0.80 * ridgeHighlight);
  outputIntensity *= distanceFade;
  
  return outputIntensity;
}

// ============================================================================
// 3D SHAPE RENDERING
// ============================================================================

float renderCloudShape(vec2 screenUV, vec2 mouseUV, float time) {
  vec3 cameraPosition = SHAPE_CAMERA_POSITION;
  vec3 rayDirection = normalize(vec3(screenUV, -SHAPE_CAMERA_FOV));
  
  float morphTime = time * 0.5;
  float hitDistance = rayMarch(cameraPosition, rayDirection, morphTime);
  
  if (hitDistance < 0.0) {
    return 0.0;
  }
  
  vec3 hitPosition = cameraPosition + rayDirection * hitDistance;
  vec3 surfaceNormal = calculateNormal(hitPosition, morphTime);
  
  // Apply rotation to sample point for animated noise
  float rotationAngle = time * 0.25;
  mat3 rotationMatrix = rotateY(rotationAngle) * rotateX(time * 0.15);
  vec3 rotatedSamplePoint = rotationMatrix * hitPosition;
  
  // Multi-octave noise for cloud density
  float noiseTime = time * 0.2;
  float noiseScale = 0.5;
  float noiseCoarse = snoise3(rotatedSamplePoint * noiseScale + vec3(noiseTime, 0.0, noiseTime * 0.7));
  float noiseMedium = snoise3(rotatedSamplePoint * noiseScale * 2.0 + vec3(-noiseTime * 0.8, noiseTime * 0.5, 0.0)) * 0.5;
  float noiseFine = snoise3(rotatedSamplePoint * noiseScale * 4.0 + vec3(0.0, -noiseTime * 0.6, noiseTime * 0.4)) * 0.25;
  
  float combinedNoise = noiseCoarse + noiseMedium + noiseFine;
  float cloudDensity = smoothstep(-0.5, 1.2, combinedNoise);
  
  // Fresnel effect for edge glow
  float fresnelFactor = 1.0 - abs(dot(surfaceNormal, -rayDirection));
  fresnelFactor = pow(fresnelFactor, 1.5);
  cloudDensity = mix(cloudDensity, cloudDensity * 1.3, fresnelFactor * 0.5);
  
  // Soften edges
  float edgeDistance = abs(getMorphedShapeSDF(hitPosition, morphTime));
  float edgeFade = smoothstep(0.0, 0.15, edgeDistance);
  cloudDensity *= 1.0 - edgeFade * 0.3;
  
  // Mouse repulsion effect
  float mouseDistance = length(screenUV - mouseUV);
  const float REPEL_RADIUS = 0.35;
  const float REPEL_STRENGTH = 0.20;
  
  if (mouseDistance < REPEL_RADIUS) {
    float repelFalloff = 1.0 - mouseDistance / REPEL_RADIUS;
    repelFalloff = repelFalloff * repelFalloff * repelFalloff;
    cloudDensity *= 1.0 - repelFalloff * REPEL_STRENGTH;
  }
  
  return cloudDensity;
}

// ============================================================================
// GRAIN / STIPPLE EFFECT
// ============================================================================

float renderGrainEffect(vec2 pixelCoord, vec2 screenUV, vec2 mouseUV, float inputDensity, float time) {
  const float SHIMMER_AMOUNT = 0.015;
  float animatedTime = time * 0.08;
  
  // Mouse influence on grain
  float mouseDistance = length(screenUV - mouseUV);
  float mouseInfluence = smoothstep(0.4, 0.0, mouseDistance) * 0.02;
  
  // Animated grain offset
  vec2 grainOffset = vec2(
    snoise(pixelCoord * 0.01 + animatedTime * 0.05),
    snoise(pixelCoord * 0.01 + 100.0 + animatedTime * 0.04)
  ) * (SHIMMER_AMOUNT + mouseInfluence);
  
  // Push grain away from mouse
  if (mouseDistance < 0.4 && mouseDistance > 0.001) {
    vec2 pushDirection = normalize(screenUV - mouseUV);
    grainOffset += pushDirection * mouseInfluence * 50.0;
  }
  
  vec2 samplingCoord = pixelCoord + grainOffset;
  
  // Multi-frequency grain layers
  float grainCoarse = fract(sin(dot(samplingCoord, vec2(12.9898, 78.233))) * 43758.5453);
  float grainMedium = fract(sin(dot(samplingCoord * 0.5 + 50.0, vec2(63.7264, 10.873))) * 28947.2934);
  float grainFine = fract(sin(dot(samplingCoord * 2.0 + 100.0, vec2(91.2834, 45.164))) * 61532.8372);
  
  float combinedGrain = grainCoarse * 0.5 + grainMedium * 0.3 + grainFine * 0.2;
  
  // Threshold for stipple effect
  float stippleThreshold = 1.0 - inputDensity * 0.75;
  float stippleResult = smoothstep(stippleThreshold, stippleThreshold + 0.12, combinedGrain);
  
  return stippleResult * inputDensity;
}

// ============================================================================
// CAMERA UTILITIES
// ============================================================================

struct Camera {
  vec3 position;
  vec3 right;
  vec3 up;
  vec3 forward;
};

Camera createFloorCamera() {
  Camera cam;
  cam.position = FLOOR_CAMERA_POSITION;
  cam.forward = normalize(FLOOR_CAMERA_TARGET - cam.position);
  cam.right = normalize(cross(vec3(0.0, 1.0, 0.0), cam.forward));
  cam.up = cross(cam.forward, cam.right);
  return cam;
}

vec3 getRayDirection(Camera cam, vec2 uv, float fov) {
  return normalize(cam.right * uv.x + cam.up * uv.y + cam.forward * fov);
}

// ============================================================================
// MAIN
// ============================================================================

void main() {
  vec2 pixelCoord = gl_FragCoord.xy;
  vec2 screenUV = (pixelCoord - 0.5 * iResolution.xy) / iResolution.y;
  vec2 mouseScreenUV = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;
  float currentTime = iTime;
  
  // Setup floor camera
  Camera floorCamera = createFloorCamera();
  vec3 floorRayDirection = getRayDirection(floorCamera, screenUV, FLOOR_CAMERA_FOV);
  
  // Trace floor
  FloorHit floorHit = traceFloor(floorCamera.position, floorRayDirection, currentTime);
  
  float floorIntensity = 0.0;
  if (floorHit.hit) {
    // Project mouse onto floor plane
    vec3 mouseRayDirection = getRayDirection(floorCamera, mouseScreenUV, FLOOR_CAMERA_FOV);
    float mouseRayDistance = -floorCamera.position.y / mouseRayDirection.y;
    vec2 mouseWorldPosition = floorCamera.position.xz + mouseRayDirection.xz * mouseRayDistance;
    
    floorIntensity = calculateFloorIntensity(floorHit, mouseWorldPosition, currentTime);
  }
  
  // Render 3D cloud shape
  float cloudDensity = renderCloudShape(screenUV, mouseScreenUV, currentTime);
  
  // Apply grain effect to cloud
  float grainIntensity = renderGrainEffect(pixelCoord, screenUV, mouseScreenUV, cloudDensity, currentTime);
  
  // Final composition
  float backgroundValue = BACKGROUND_GRAY - grainIntensity * GRAIN_DARKNESS;
  vec3 backgroundColor = vec3(backgroundValue);
  vec3 dotColor = vec3(0.0);
  
  vec3 finalColor = mix(backgroundColor, dotColor, floorIntensity);
  
  fragColor = vec4(finalColor, 1.0);
}
