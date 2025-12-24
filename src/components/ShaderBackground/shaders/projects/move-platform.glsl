// ============================================================================
// MOVE PLATFORM - The Weave
// Turbulent flowing weave pattern representing interconnected marketplace
// Based on "The Weave" by chronos - volume traced distorted SDFs
// ============================================================================

// ============================================================================
// CONFIGURATION
// ============================================================================

const float MOVE_SHAPE_RADIUS = 0.15;
const float MOVE_TIME_SPEED = 0.5;

// Cloud density overrides - fuller cloud to show effect clearly
const float MOVE_CLOUD_THRESHOLD_LOW = -2.0;
const float MOVE_CLOUD_THRESHOLD_HIGH = 0.5;

// ============================================================================
// WEAVE PATTERN
// Turbulently distorted volume with accumulated glow
// The weave represents the interconnected network of buyers/sellers
// ============================================================================

float renderWeavePattern(vec2 uv, float time) {
  float focal = 2.25;
  vec3 ro = vec3(0.0, 0.0, time);
  vec3 rd = normalize(vec3(uv, -focal));
  
  float intensity = 0.0;
  float t = 0.0;
  
  for (int i = 0; i < 80; i++) {
    vec3 p = t * rd + ro;
    
    // Time-based rotation
    float T = (t + time) / 5.0;
    float c = cos(T), s = sin(T);
    p.xy = mat2(c, -s, s, c) * p.xy;
    
    // === THE KEY: Turbulent distortion ===
    // This creates the beautiful weaving effect
    for (float f = 0.0; f < 9.0; f++) {
      float a = exp(f) / exp2(f);
      p += cos(p.yzx * a + time) / a;
    }
    
    // Distance to distorted surface
    float d = 1.0/50.0 + abs((ro - p - vec3(0.0, 1.0, 0.0)).y - 1.0) / 10.0;
    
    // Accumulate glow - grayscale version
    intensity += 2e-3 / d;
    
    t += d;
    if (t > 10.0) break;
  }
  
  // Tone mapping - softened from reference
  intensity = intensity * intensity;
  intensity = 1.0 - exp(-intensity * 0.5);
  
  // Center focus - gentler falloff
  float centerDist = length(uv);
  intensity *= 1.0 / (centerDist * 0.3 + 0.5);
  
  return clamp(intensity * 0.7, 0.0, 1.0);
}

// ============================================================================
// SHAPE RENDERING
// Uses shared shape morphing from default.glsl, adds weave pattern
// ============================================================================

float renderMovePlatformShape(vec2 screenUV, vec2 mouseUV, float globalTime, float projectTime, float blend) {
  vec3 cameraPosition = SHAPE_CAMERA_POSITION;
  vec3 rayDirection = normalize(vec3(screenUV, -SHAPE_CAMERA_FOV));
  
  // Use GLOBAL time for shape morphing - keeps continuity with default shader
  float morphTime = globalTime * 0.5;
  float hitDistance = rayMarchDefault(cameraPosition, rayDirection, morphTime);
  
  if (hitDistance < 0.0) {
    return 0.0;
  }
  
  vec3 hitPosition = cameraPosition + rayDirection * hitDistance;
  vec3 surfaceNormal = calculateDefaultNormal(hitPosition, morphTime);
  
  // Use GLOBAL time for noise rotation
  float rotationAngle = globalTime * CLOUD_ROTATION_SPEED;
  mat3 rotationMatrix = rotateY(rotationAngle) * rotateX(globalTime * 0.15);
  vec3 rotatedSamplePoint = rotationMatrix * hitPosition;
  
  // Multi-octave noise
  float noiseTime = globalTime * CLOUD_NOISE_SPEED;
  float noiseCoarse = snoise3(rotatedSamplePoint * CLOUD_NOISE_SCALE + vec3(noiseTime, 0.0, noiseTime * 0.7));
  float noiseMedium = snoise3(rotatedSamplePoint * CLOUD_NOISE_SCALE * 2.0 + vec3(-noiseTime * 0.8, noiseTime * 0.5, 0.0)) * 0.5;
  float noiseFine = snoise3(rotatedSamplePoint * CLOUD_NOISE_SCALE * 4.0 + vec3(0.0, -noiseTime * 0.6, noiseTime * 0.4)) * 0.25;
  
  float combinedNoise = noiseCoarse + noiseMedium + noiseFine;
  
  // Blend cloud thresholds - fuller cloud when pattern is active
  float thresholdLow = mix(CLOUD_THRESHOLD_LOW, MOVE_CLOUD_THRESHOLD_LOW, blend);
  float thresholdHigh = mix(CLOUD_THRESHOLD_HIGH, MOVE_CLOUD_THRESHOLD_HIGH, blend);
  float cloudDensity = smoothstep(thresholdLow, thresholdHigh, combinedNoise);
  
  // Fresnel effect for edge glow
  float fresnelFactor = 1.0 - abs(dot(surfaceNormal, -rayDirection));
  fresnelFactor = pow(fresnelFactor, 1.5);
  cloudDensity = mix(cloudDensity, cloudDensity * 1.3, fresnelFactor * 0.5);
  
  // Soften edges
  float edgeDistance = abs(getMorphedShapeSDF(hitPosition, morphTime));
  float edgeFade = smoothstep(0.0, 0.15, edgeDistance);
  cloudDensity *= 1.0 - edgeFade * 0.3;
  
  // === WEAVE PATTERN CUTOUT (fades in/out with transition) ===
  vec2 scaledUV = screenUV / MOVE_SHAPE_RADIUS;
  float weave = renderWeavePattern(scaledUV, globalTime * MOVE_TIME_SPEED);
  
  // Carve out weave pattern - strength controlled by blend
  float cutoutStrength = 0.75 * blend;
  cloudDensity *= (1.0 - weave * cutoutStrength);
  
  return cloudDensity;
}

// ============================================================================
// FLOOR INTENSITY
// Keep default dot matrix floor
// ============================================================================

float calculateMovePlatformFloorIntensity(FloorHit floorHit, vec2 mouseWorldPos, float time, float blend) {
  return calculateDefaultFloorIntensity(floorHit, mouseWorldPos, time);
}
