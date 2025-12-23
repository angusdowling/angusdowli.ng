// ============================================================================
// CONTENT INTELLIGENCE - 3D Wireframe Lattice
// Geodesic grid that wraps around the morphing shape surface
// Represents spatial understanding and dimensional analysis
// ============================================================================

// ============================================================================
// LATTICE CONFIGURATION
// ============================================================================

// Grid density
const float CI_GRID_SCALE = 20.0;           // Density of grid lines
const float CI_LINE_WIDTH = 0.001;         // Thickness of grid lines
const float CI_LINE_SOFTNESS = 0.015;      // Anti-aliasing softness

// Vertex dots at intersections
const float CI_DOT_SIZE = 0.01;            // Size of intersection dots

// Animation
const float CI_ROTATION_SPEED = 0.12;      // How fast the lattice rotates

// Visual tuning  
const float CI_LINE_BRIGHTNESS = 0.45;     // Base brightness of lines
const float CI_DOT_BRIGHTNESS = 0.55;      // Brightness of intersection dots

// Cloud density - fuller to show lattice clearly
const float CI_CLOUD_THRESHOLD_LOW = -2.0;
const float CI_CLOUD_THRESHOLD_HIGH = 0.5;

// ============================================================================
// CONTOUR + RADIAL LATTICE
// Horizontal contour lines + vertical radial lines that follow any shape
// ============================================================================

float renderLattice(vec3 hitPosition, vec3 surfaceNormal, vec3 rayDirection, float time) {
  // Apply slow rotation to the lattice
  float rotAngle = time * CI_ROTATION_SPEED;
  mat3 rot = rotateY(rotAngle);
  vec3 p = rot * hitPosition;
  
  // === HORIZONTAL CONTOUR LINES ===
  // Lines at regular height intervals - like topographic contours
  float yScaled = p.y * CI_GRID_SCALE;
  float yGrid = fract(yScaled);
  float yDist = min(yGrid, 1.0 - yGrid);
  float horizontalLines = 1.0 - smoothstep(CI_LINE_WIDTH, CI_LINE_WIDTH + CI_LINE_SOFTNESS, yDist);
  
  // === VERTICAL RADIAL LINES ===
  // Lines radiating from center based on angle around Y axis
  float angle = atan(p.z, p.x); // -PI to PI
  float angleNorm = (angle + 3.14159265) / (2.0 * 3.14159265); // 0 to 1
  float numRadialLines = CI_GRID_SCALE * 2.0;
  float angleGrid = fract(angleNorm * numRadialLines);
  float angleDist = min(angleGrid, 1.0 - angleGrid);
  
  // Adjust line width based on distance from Y axis (prevents bunching at center)
  float radialDist = length(p.xz);
  float adjustedWidth = CI_LINE_WIDTH / max(radialDist * 2.0, 0.5);
  float verticalLines = 1.0 - smoothstep(adjustedWidth, adjustedWidth + CI_LINE_SOFTNESS, angleDist);
  
  // Fade vertical lines near poles (top/bottom) where they converge
  float poleBlend = smoothstep(0.0, 0.15, radialDist);
  verticalLines *= poleBlend;
  
  // === COMBINE LINES ===
  float lines = max(horizontalLines, verticalLines);
  
  // === INTERSECTION DOTS ===
  // Dots where horizontal and vertical lines cross
  float dotDist = length(vec2(yDist, angleDist * radialDist));
  float dots = 1.0 - smoothstep(CI_DOT_SIZE, CI_DOT_SIZE + 0.015, dotDist);
  dots *= poleBlend; // Also fade dots near poles
  
  // === COMBINE ===
  float pattern = lines * CI_LINE_BRIGHTNESS;
  pattern = max(pattern, dots * CI_DOT_BRIGHTNESS);
  
  return clamp(pattern, 0.0, 1.0);
}

// ============================================================================
// SHAPE RENDERING (with Lattice overlay)
// Uses shared shape morphing from default.glsl, adds wireframe lattice
// ============================================================================

float renderContentIntelligenceShape(vec2 screenUV, vec2 mouseUV, float globalTime, float projectTime, float blend) {
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
  
  // Blend cloud thresholds - fuller cloud when lattice is active
  float thresholdLow = mix(CLOUD_THRESHOLD_LOW, CI_CLOUD_THRESHOLD_LOW, blend);
  float thresholdHigh = mix(CLOUD_THRESHOLD_HIGH, CI_CLOUD_THRESHOLD_HIGH, blend);
  float cloudDensity = smoothstep(thresholdLow, thresholdHigh, combinedNoise);
  
  // Fresnel effect for edge glow
  float fresnelFactor = 1.0 - abs(dot(surfaceNormal, -rayDirection));
  fresnelFactor = pow(fresnelFactor, 1.5);
  cloudDensity = mix(cloudDensity, cloudDensity * 1.3, fresnelFactor * 0.5);
  
  // Soften edges
  float edgeDistance = abs(getMorphedShapeSDF(hitPosition, morphTime));
  float edgeFade = smoothstep(0.0, 0.15, edgeDistance);
  cloudDensity *= 1.0 - edgeFade * 0.3;
  
  // === LATTICE CUTOUT (fades in/out with transition) ===
  float lattice = renderLattice(hitPosition, surfaceNormal, rayDirection, globalTime);
  
  // Carve out lattice pattern - strength controlled by blend
  float cutoutStrength = 0.92 * blend;
  cloudDensity *= (1.0 - lattice * cutoutStrength);
  
  return cloudDensity;
}

// ============================================================================
// FLOOR INTENSITY
// Keep default dot matrix floor - no custom floor effect for this project
// ============================================================================

float calculateContentIntelligenceFloorIntensity(FloorHit floorHit, vec2 mouseWorldPos, float time, float blend) {
  // Use default dot grid and letter path (unchanged from default)
  return calculateDefaultFloorIntensity(floorHit, mouseWorldPos, time);
}
