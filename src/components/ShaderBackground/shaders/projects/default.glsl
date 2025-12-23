// ============================================================================
// DEFAULT STATE - Morphing Shapes
// The neutral/idle visualization when no project is selected
// ============================================================================

// ============================================================================
// NOISE CLOUD TUNING
// ============================================================================

// Spatial frequency - higher = more detailed/frequent patterns (default: 0.5)
const float CLOUD_NOISE_SCALE = 0.5;

// Time evolution speed - higher = faster animation (default: 0.2)
const float CLOUD_NOISE_SPEED = 0.1;

// Visibility threshold - lower = more visible cloud (range: -1.5 to 0.0, default: -0.5)
const float CLOUD_THRESHOLD_LOW = -1.0;

// Contrast control - lower = denser/more opaque cloud (range: 0.5 to 2.0, default: 1.2)
const float CLOUD_THRESHOLD_HIGH = 1.1;

// Rotation speed - how fast the noise rotates on the shape (default: 0.25)
const float CLOUD_ROTATION_SPEED = 0.25;

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

float rayMarchDefault(vec3 rayOrigin, vec3 rayDirection, float morphTime) {
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

vec3 calculateDefaultNormal(vec3 surfacePoint, float morphTime) {
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
// SHAPE RENDERING
// ============================================================================

float renderDefaultShape(vec2 screenUV, vec2 mouseUV, float time) {
  vec3 cameraPosition = SHAPE_CAMERA_POSITION;
  vec3 rayDirection = normalize(vec3(screenUV, -SHAPE_CAMERA_FOV));
  
  float morphTime = time * 0.5;
  float hitDistance = rayMarchDefault(cameraPosition, rayDirection, morphTime);
  
  if (hitDistance < 0.0) {
    return 0.0;
  }
  
  vec3 hitPosition = cameraPosition + rayDirection * hitDistance;
  vec3 surfaceNormal = calculateDefaultNormal(hitPosition, morphTime);
  
  // Apply rotation to sample point for animated noise
  float rotationAngle = time * CLOUD_ROTATION_SPEED;
  mat3 rotationMatrix = rotateY(rotationAngle) * rotateX(time * 0.15);
  vec3 rotatedSamplePoint = rotationMatrix * hitPosition;
  
  // Multi-octave noise for cloud density
  float noiseTime = time * CLOUD_NOISE_SPEED;
  float noiseCoarse = snoise3(rotatedSamplePoint * CLOUD_NOISE_SCALE + vec3(noiseTime, 0.0, noiseTime * 0.7));
  float noiseMedium = snoise3(rotatedSamplePoint * CLOUD_NOISE_SCALE * 2.0 + vec3(-noiseTime * 0.8, noiseTime * 0.5, 0.0)) * 0.5;
  float noiseFine = snoise3(rotatedSamplePoint * CLOUD_NOISE_SCALE * 4.0 + vec3(0.0, -noiseTime * 0.6, noiseTime * 0.4)) * 0.25;
  
  float combinedNoise = noiseCoarse + noiseMedium + noiseFine;
  float cloudDensity = smoothstep(CLOUD_THRESHOLD_LOW, CLOUD_THRESHOLD_HIGH, combinedNoise);
  
  // Fresnel effect for edge glow
  float fresnelFactor = 1.0 - abs(dot(surfaceNormal, -rayDirection));
  fresnelFactor = pow(fresnelFactor, 1.5);
  cloudDensity = mix(cloudDensity, cloudDensity * 1.3, fresnelFactor * 0.5);
  
  // Soften edges
  float edgeDistance = abs(getMorphedShapeSDF(hitPosition, morphTime));
  float edgeFade = smoothstep(0.0, 0.15, edgeDistance);
  cloudDensity *= 1.0 - edgeFade * 0.3;
  
  return cloudDensity;
}

// ============================================================================
// FLOOR RENDERING
// ============================================================================

float calculateDefaultFloorIntensity(FloorHit floorHit, vec2 mouseWorldPos, float time) {
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

