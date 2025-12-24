// ============================================================================
// ENTERPRISE DAM ARCHITECTURE - Twisted Smoke Wisps
// Flowing smoke pattern representing hierarchical metadata layers
// Inspired by the unified schema with conditional visibility
// ============================================================================

// ============================================================================
// WISP CONFIGURATION
// ============================================================================

const float DAM_SHAPE_RADIUS = 0.55;      // Circular mask size
const float DAM_TIME_SPEED = 0.5;         // Animation speed

// Cloud density overrides - fuller cloud to show effect clearly
const float DAM_CLOUD_THRESHOLD_LOW = -2.0;
const float DAM_CLOUD_THRESHOLD_HIGH = 0.5;

// ============================================================================
// TWISTED SMOKE WISPS
// Direct adaptation of the reference shader pattern
// Creates flowing smoke lines that twist through space
// ============================================================================

float renderSmokeWisps(vec2 uv, float time) {
  float intensity = 0.0;
  float d = 0.0;  // distance marched
  float s = 0.0;  // signed distance to surface
  
  // Ray march accumulating glow
  for (float i = 0.0; i < 100.0; i++) {
    // Create position that travels into the screen
    vec3 p = vec3(uv * d, d + time + time);
    
    // Twist the xy plane based on z depth
    // This creates the spiral/tornado effect
    float angle = p.z * 0.2;
    p.xy = mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * p.xy;
    
    // Base diagonal wave pattern
    s = sin(p.y + p.x);
    
    // Subtract layered noise to create wispy detail
    // This is the key to the smoke look - fractal noise at multiple scales
    for (float n = 1.0; n < 32.0; n *= 2.0) {
      vec3 noisePos = p * n + time * 0.3;
      s -= abs(dot(cos(noisePos), vec3(0.3))) / n;
    }
    
    // Distance step - smaller near surfaces (where s is small)
    float stepDist = 0.01 + abs(s) * 0.8;
    
    // Accumulate glow - brighter where s is near zero (the wisp lines)
    intensity += 1.0 / stepDist;
    
    d += stepDist;
    if (d > 8.0) break;
  }
  
  // Normalize with center focus
  float centerDist = length(uv);
  intensity = intensity / 20000.0 / (centerDist * 0.5 + 0.08);
  
  // Apply tanh for soft clamping
  intensity = tanh(intensity * 3.0);
  
  return clamp(intensity, 0.0, 1.0);
}

// ============================================================================
// SHAPE RENDERING
// Uses shared shape morphing from default.glsl, adds smoke wisp pattern
// ============================================================================

float renderEnterpriseDAMShape(vec2 screenUV, vec2 mouseUV, float globalTime, float projectTime, float blend) {
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
  float thresholdLow = mix(CLOUD_THRESHOLD_LOW, DAM_CLOUD_THRESHOLD_LOW, blend);
  float thresholdHigh = mix(CLOUD_THRESHOLD_HIGH, DAM_CLOUD_THRESHOLD_HIGH, blend);
  float cloudDensity = smoothstep(thresholdLow, thresholdHigh, combinedNoise);
  
  // Fresnel effect for edge glow
  float fresnelFactor = 1.0 - abs(dot(surfaceNormal, -rayDirection));
  fresnelFactor = pow(fresnelFactor, 1.5);
  cloudDensity = mix(cloudDensity, cloudDensity * 1.3, fresnelFactor * 0.5);
  
  // Soften edges
  float edgeDistance = abs(getMorphedShapeSDF(hitPosition, morphTime));
  float edgeFade = smoothstep(0.0, 0.15, edgeDistance);
  cloudDensity *= 1.0 - edgeFade * 0.3;
  
  // === SMOKE WISPS CUTOUT (fades in/out with transition) ===
  vec2 scaledUV = screenUV / DAM_SHAPE_RADIUS;
  float wisps = renderSmokeWisps(scaledUV, globalTime * DAM_TIME_SPEED);
  
  // Carve out wisp pattern - strength controlled by blend
  float cutoutStrength = 0.95 * blend;
  cloudDensity *= (1.0 - wisps * cutoutStrength);
  
  return cloudDensity;
}

// ============================================================================
// FLOOR INTENSITY
// Keep default dot matrix floor - wisps live in the shape
// ============================================================================

float calculateEnterpriseDAMFloorIntensity(FloorHit floorHit, vec2 mouseWorldPos, float time, float blend) {
  return calculateDefaultFloorIntensity(floorHit, mouseWorldPos, time);
}
