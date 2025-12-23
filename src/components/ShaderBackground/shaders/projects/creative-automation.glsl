// ============================================================================
// CREATIVE AUTOMATION - Flowing Current Pattern
// Organic ocean currents representing automated template generation
// Data flowing from templates to variants like water currents
// ============================================================================

// ============================================================================
// CURRENT CONFIGURATION
// ============================================================================

// Flow dynamics
const float CA_FLOW_SPEED = 0.05;          // Speed of current drift
const float CA_WAVE_FREQUENCY = 3.0;       // Base frequency of wave pattern
const float CA_WAVE_AMPLITUDE = 0.35;      // Wave intensity
const int CA_OCTAVES = 6;                  // FBM detail level

// Visual style
const float CA_SHAPE_RADIUS = 0.55;        // Circular mask size
const float CA_PATTERN_SCALE = 2.5;        // Overall pattern scaling
const float CA_DRIFT_SPEED = 0.02;         // Vertical drift rate

// Dithering
const float CA_COLOR_LEVELS = 4.0;         // Number of quantization levels
const float CA_DITHER_STRENGTH = 0.85;     // How much dithering affects output

// Cloud density overrides - fuller cloud to show effect clearly
const float CA_CLOUD_THRESHOLD_LOW = -2.0;  // Lower = more visible (default: -1.25)
const float CA_CLOUD_THRESHOLD_HIGH = 0.5;  // Lower = denser/more opaque (default: 1.1)

// ============================================================================
// PERLIN NOISE (Classic for smooth currents)
// ============================================================================

vec2 caFade(vec2 t) { 
  return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); 
}

float caPerlin(vec2 P) {
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod289(Pi);
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute(permute(ix) + iy);
  vec4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0;
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x, gy.x);
  vec2 g10 = vec2(gx.y, gy.y);
  vec2 g01 = vec2(gx.z, gy.z);
  vec2 g11 = vec2(gx.w, gy.w);
  vec4 norm = taylorInvSqrt(vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
  g00 *= norm.x; g01 *= norm.y; g10 *= norm.z; g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = caFade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  return 2.3 * mix(n_x.x, n_x.y, fade_xy.y);
}

// ============================================================================
// FRACTAL BROWNIAN MOTION
// Multi-octave noise for organic flow patterns
// ============================================================================

float caFbm(vec2 p, float freq, float amp) {
  float value = 0.0;
  float amplitude = 1.0;
  float frequency = freq;
  
  for (int i = 0; i < CA_OCTAVES; i++) {
    value += amplitude * abs(caPerlin(p));
    p *= frequency;
    amplitude *= amp;
  }
  
  return value;
}

// ============================================================================
// DOMAIN WARPING
// Creates flowing current effect by distorting space recursively
// ============================================================================

float caCurrentPattern(vec2 p, float time) {
  // Apply vertical drift (templates flowing to variants)
  vec2 driftP = p;
  driftP.y += time * CA_DRIFT_SPEED;
  
  // Time-offset pattern for animation
  vec2 animP = driftP - time * CA_FLOW_SPEED;
  
  // Triple domain warping for deep organic flow
  float warp1 = caFbm(animP, CA_WAVE_FREQUENCY, CA_WAVE_AMPLITUDE);
  float warp2 = caFbm(driftP + warp1, CA_WAVE_FREQUENCY, CA_WAVE_AMPLITUDE);
  float pattern = caFbm(driftP - warp2, CA_WAVE_FREQUENCY, CA_WAVE_AMPLITUDE);
  
  return pattern;
}

// ============================================================================
// BAYER DITHERING
// 8x8 ordered dithering for retro/print aesthetic
// Represents the discrete, templated nature of design automation
// ============================================================================

float caBayerMatrix8x8(int x, int y) {
  // Computed Bayer 8x8 pattern
  int index = y * 8 + x;
  
  // Bayer pattern values (0-63 mapped to 0-1)
  float pattern[64] = float[64](
     0.0, 48.0, 12.0, 60.0,  3.0, 51.0, 15.0, 63.0,
    32.0, 16.0, 44.0, 28.0, 35.0, 19.0, 47.0, 31.0,
     8.0, 56.0,  4.0, 52.0, 11.0, 59.0,  7.0, 55.0,
    40.0, 24.0, 36.0, 20.0, 43.0, 27.0, 39.0, 23.0,
     2.0, 50.0, 14.0, 62.0,  1.0, 49.0, 13.0, 61.0,
    34.0, 18.0, 46.0, 30.0, 33.0, 17.0, 45.0, 29.0,
    10.0, 58.0,  6.0, 54.0,  9.0, 57.0,  5.0, 53.0,
    42.0, 26.0, 38.0, 22.0, 41.0, 25.0, 37.0, 21.0
  );
  
  return pattern[index] / 64.0;
}

float caDither(vec2 screenUV, float value) {
  // Convert UV to pixel coordinates for dithering
  vec2 pixelCoord = (screenUV + 0.5) * 400.0; // Approximate screen density
  int x = int(mod(pixelCoord.x, 8.0));
  int y = int(mod(pixelCoord.y, 8.0));
  
  float threshold = caBayerMatrix8x8(x, y) - 0.25;
  float dithered = value + threshold * CA_DITHER_STRENGTH * 0.3;
  
  // Quantize to discrete levels
  return floor(dithered * (CA_COLOR_LEVELS - 1.0) + 0.5) / (CA_COLOR_LEVELS - 1.0);
}

// ============================================================================
// CURRENT RENDERING
// Generates the flowing pattern for the 3D shape
// ============================================================================

float renderCurrentFlow(vec2 screenUV, float time) {
  vec2 uv = screenUV * CA_PATTERN_SCALE;
  
  // Generate flowing current pattern
  float pattern = caCurrentPattern(uv, time);
  
  // Normalize to 0-1 range
  pattern = clamp(pattern * 0.5, 0.0, 1.0);
  
  // Apply dithering for discrete aesthetic
  float dithered = caDither(screenUV, pattern);
  
  // Create bands/levels in the flow
  float banded = smoothstep(0.0, 0.3, dithered) * 
                 smoothstep(1.0, 0.7, dithered);
  
  // Mix dithered and smooth for depth
  float result = mix(banded, dithered, 0.6);
  
  return result;
}

// ============================================================================
// SHAPE RENDERING
// Uses shared shape morphing from default.glsl, adds current flow carving
// ============================================================================

float renderCreativeAutomationShape(vec2 screenUV, vec2 mouseUV, float globalTime, float projectTime, float blend) {
  // Use the same camera setup as default shader
  vec3 cameraPosition = SHAPE_CAMERA_POSITION;
  vec3 rayDirection = normalize(vec3(screenUV, -SHAPE_CAMERA_FOV));
  
  // Use GLOBAL time for shape morphing - keeps continuity with default shader
  float morphTime = globalTime * 0.5;
  float hitDistance = rayMarchDefault(cameraPosition, rayDirection, morphTime);
  
  // No hit = no shape
  if (hitDistance < 0.0) {
    return 0.0;
  }
  
  vec3 hitPosition = cameraPosition + rayDirection * hitDistance;
  vec3 surfaceNormal = calculateDefaultNormal(hitPosition, morphTime);
  
  // Use GLOBAL time for noise rotation - keeps continuity with default shader
  float rotationAngle = globalTime * CLOUD_ROTATION_SPEED;
  mat3 rotationMatrix = rotateY(rotationAngle) * rotateX(globalTime * 0.15);
  vec3 rotatedSamplePoint = rotationMatrix * hitPosition;
  
  // Multi-octave noise
  float noiseTime = globalTime * CLOUD_NOISE_SPEED;
  float noiseCoarse = snoise3(rotatedSamplePoint * CLOUD_NOISE_SCALE + vec3(noiseTime, 0.0, noiseTime * 0.7));
  float noiseMedium = snoise3(rotatedSamplePoint * CLOUD_NOISE_SCALE * 2.0 + vec3(-noiseTime * 0.8, noiseTime * 0.5, 0.0)) * 0.5;
  float noiseFine = snoise3(rotatedSamplePoint * CLOUD_NOISE_SCALE * 4.0 + vec3(0.0, -noiseTime * 0.6, noiseTime * 0.4)) * 0.25;
  
  float combinedNoise = noiseCoarse + noiseMedium + noiseFine;
  
  // Blend cloud thresholds based on transition - fuller cloud when active
  float thresholdLow = mix(CLOUD_THRESHOLD_LOW, CA_CLOUD_THRESHOLD_LOW, blend);
  float thresholdHigh = mix(CLOUD_THRESHOLD_HIGH, CA_CLOUD_THRESHOLD_HIGH, blend);
  float cloudDensity = smoothstep(thresholdLow, thresholdHigh, combinedNoise);
  
  // Fresnel effect for edge glow
  float fresnelFactor = 1.0 - abs(dot(surfaceNormal, -rayDirection));
  fresnelFactor = pow(fresnelFactor, 1.5);
  cloudDensity = mix(cloudDensity, cloudDensity * 1.3, fresnelFactor * 0.5);
  
  // Soften edges
  float edgeDistance = abs(getMorphedShapeSDF(hitPosition, morphTime));
  float edgeFade = smoothstep(0.0, 0.15, edgeDistance);
  cloudDensity *= 1.0 - edgeFade * 0.3;
  
  // === CURRENT FLOW CUTOUT (fades in/out with transition) ===
  vec2 scaledUV = screenUV / CA_SHAPE_RADIUS;
  float currentFlow = renderCurrentFlow(scaledUV, globalTime);
  
  // Carve out current pattern - strength controlled by blend
  float cutoutStrength = 0.90 * blend;
  cloudDensity *= (1.0 - currentFlow * cutoutStrength);
  
  return cloudDensity;
}

// ============================================================================
// FLOOR INTENSITY
// Keep default dot matrix floor - no custom floor effect for this project
// ============================================================================

float calculateCreativeAutomationFloorIntensity(FloorHit floorHit, vec2 mouseWorldPos, float time, float blend) {
  // Use default dot grid and letter path (unchanged from default)
  return calculateDefaultFloorIntensity(floorHit, mouseWorldPos, time);
}
