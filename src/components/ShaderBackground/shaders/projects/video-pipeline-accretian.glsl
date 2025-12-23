// ============================================================================
// VIDEO RENDERING PLATFORM - Project 1
// Accretion disk effect (inspired by @XorDev)
// Adapted to monochromatic aesthetic
// ============================================================================

const float PI = 3.14159265;

// Accretion configuration
const float ACCRETION_FOCAL = 0.8;           // Camera focal length
const float ACCRETION_DISK_RADIUS = 5.0;     // Base disk radius
const float ACCRETION_DEPTH_SCALE = 0.18;    // How depth affects radius
const float ACCRETION_POLAR_SCALE = 2.0;     // Polar coordinate scaling
const float ACCRETION_Z_SCALE = 3.0;         // Z coordinate scaling

// Turbulence configuration
const float TURB_ITERATIONS = 7.0;           // Turbulence detail
const float TURB_REFRACTION = 0.25;          // Refraction effect strength
const float TURB_SPEED = 0.8;                // Animation speed

// Rendering
const float RAY_STEPS = 20.0;                // Raymarch iterations
const float TONEMAP_SCALE = 350.0;           // Intensity mapping
const float SHAPE_BOUNDS = 0.6;              // Visible area radius

// Glitch configuration
const float GLITCH_INTENSITY = 0.015;
const float GLITCH_FREQUENCY = 2.5;

// ============================================================================
// GLITCH EFFECT
// ============================================================================

float getGlitchOffset(float y, float time) {
  float glitchTime = floor(time * GLITCH_FREQUENCY);
  float glitchPhase = fract(time * GLITCH_FREQUENCY);
  
  // Only glitch during brief windows
  float glitchActive = smoothstep(0.0, 0.1, glitchPhase) * (1.0 - smoothstep(0.15, 0.25, glitchPhase));
  
  float noise1 = snoise(vec2(y * 10.0, glitchTime));
  float noise2 = snoise(vec2(y * 30.0, glitchTime + 100.0));
  float bandNoise = step(0.7, snoise(vec2(y * 5.0, glitchTime)));
  
  return (noise1 * 0.5 + noise2 * 0.5) * GLITCH_INTENSITY * glitchActive * bandNoise;
}

// ============================================================================
// ACCRETION DISK RENDERING
// ============================================================================

float calculateAccretionDensity(vec2 screenUV, float time) {
  // Raymarch state
  float z = 0.0;   // Depth
  float d = 0.0;   // Step distance
  float intensity = 0.0;
  
  // Resolution for ray direction (simulate iResolution behavior)
  vec3 resolution = vec3(1.0, 1.0, 1.0);
  
  // Raymarch through the accretion disk
  for (float i = 0.0; i < RAY_STEPS; i++) {
    // Sample point from ray direction
    // The +0.1 offset prevents singularity at center
    vec3 p = z * normalize(vec3(screenUV * 2.0, -ACCRETION_FOCAL)) + 0.1;
    
    // Transform to polar coordinates with depth warping
    // This creates the disk/tunnel structure
    float angle = atan(p.y, p.x * 0.2) * ACCRETION_POLAR_SCALE;
    float radius = length(p.xy);
    float zWarp = p.z / ACCRETION_Z_SCALE;
    float diskDist = radius - ACCRETION_DISK_RADIUS - z * ACCRETION_DEPTH_SCALE;
    
    p = vec3(angle, zWarp, diskDist);
    
    // Turbulence with refraction effect
    // The key insight: adding raymarch iterator creates beautiful refraction
    d = 0.0;
    for (float j = 1.0; j <= TURB_ITERATIONS; j++) {
      p += sin(p.yzx * j + time * TURB_SPEED + TURB_REFRACTION * i) / j;
      d = j; // Track iterations for distance calc
    }
    
    // Distance function: cylinder with waves
    // The cos(p) creates the wavy surface
    float surfaceDist = length(vec4(0.4 * cos(p) - 0.4, p.z));
    
    // Step forward
    z += surfaceDist;
    
    // Accumulate intensity (brighter where surface is closer)
    // Using a sin-based variation for visual interest
    float brightness = 1.0 + 0.4 * sin(p.x + i * 0.3 + z * 0.5);
    intensity += brightness / max(surfaceDist, 0.01);
  }
  
  // Normalize with tanh-style tonemapping for soft rolloff
  float raw = intensity * intensity / TONEMAP_SCALE;
  float mapped = raw / (1.0 + raw); // Soft clamp instead of tanh
  
  return mapped;
}

// ============================================================================
// MAIN SHAPE RENDERING
// ============================================================================

float renderPipelineShape(vec2 screenUV, vec2 mouseUV, float time) {
  // Apply glitch offset
  float glitchOffset = getGlitchOffset(screenUV.y, time);
  vec2 glitchedUV = screenUV + vec2(glitchOffset, 0.0);
  
  // Soft circular mask
  float dist = length(glitchedUV);
  float shapeMask = smoothstep(SHAPE_BOUNDS, SHAPE_BOUNDS * 0.6, dist);
  
  // Early exit for performance
  if (shapeMask < 0.01) {
    return 0.0;
  }
  
  // Calculate accretion density
  float density = calculateAccretionDensity(glitchedUV, time);
  
  // Add subtle noise variation for organic feel
  float noiseTime = time * 0.15;
  vec3 noiseCoord = vec3(glitchedUV * 1.5, noiseTime);
  float noiseVar = snoise3(noiseCoord) * 0.25 + 0.85;
  density *= noiseVar;
  
  // Apply shape mask
  float cloudDensity = density * shapeMask;
  
  // Mouse repulsion effect
  float mouseDistance = length(screenUV - mouseUV);
  const float REPEL_RADIUS = 0.35;
  const float REPEL_STRENGTH = 0.25;
  
  if (mouseDistance < REPEL_RADIUS) {
    float repelFalloff = 1.0 - mouseDistance / REPEL_RADIUS;
    repelFalloff = repelFalloff * repelFalloff * repelFalloff;
    cloudDensity *= 1.0 - repelFalloff * REPEL_STRENGTH;
  }
  
  return clamp(cloudDensity, 0.0, 1.0);
}

// ============================================================================
// VORTEX DOT GRID
// ============================================================================

// Vortex flow configuration
const float VORTEX_ROTATION_STRENGTH = 0.6;
const float VORTEX_INWARD_PULL = 0.1;
const float VORTEX_WAVE_STRENGTH = 0.05;
const float VORTEX_RADIUS = 4.0;
const float VORTEX_EDGE_SOFTNESS = 1.5;

// Calculate vortex displacement for a dot
vec2 getVortexOffset(vec2 originalPos, float time, float blend) {
  float dist = length(originalPos);
  
  // Smooth falloff at vortex edge
  float edgeFalloff = 1.0 - smoothstep(VORTEX_RADIUS - VORTEX_EDGE_SOFTNESS, VORTEX_RADIUS, dist);
  
  // Additional falloff near center
  float centerFalloff = smoothstep(0.0, 0.5, dist);
  
  float strength = blend * edgeFalloff * centerFalloff;
  
  if (strength < 0.001) {
    return vec2(0.0);
  }
  
  // Spiral rotation - closer to center = faster rotation
  float rotSpeed = VORTEX_ROTATION_STRENGTH / (dist + 0.3);
  float rotAngle = time * rotSpeed * strength;
  
  float c = cos(rotAngle);
  float s = sin(rotAngle);
  vec2 rotatedPos = mat2(c, s, -s, c) * originalPos;
  
  // Inward pull toward center
  vec2 radialDir = -normalize(originalPos + vec2(0.001));
  float pullAmount = VORTEX_INWARD_PULL * strength * dist;
  vec2 pulledPos = rotatedPos + radialDir * pullAmount;
  
  // Radial wave distortion
  float wave = sin(dist * 3.0 - time * 2.0) * VORTEX_WAVE_STRENGTH * strength;
  pulledPos += radialDir * wave;
  
  return pulledPos - originalPos;
}

// Render dot grid with vortex displacement
float renderVortexDotGrid(vec2 worldPosition, float gridScale, vec2 mouseWorldPos, float time, float blend) {
  vec2 gridPosition = worldPosition * gridScale;
  vec2 currentCell = floor(gridPosition);
  float outputIntensity = 0.0;
  
  // Check if we're near the vortex - if so, search larger area
  float distFromCenter = length(worldPosition);
  int searchRadius = distFromCenter < VORTEX_RADIUS + 2.0 ? 3 : 1;
  
  // Search neighborhood
  for (int offsetX = -searchRadius; offsetX <= searchRadius; offsetX++) {
    for (int offsetY = -searchRadius; offsetY <= searchRadius; offsetY++) {
      vec2 neighborCell = currentCell + vec2(float(offsetX), float(offsetY));
      
      // Get original dot position (with mouse repulsion)
      vec2 originalDotPos = getDotWorldPosition(neighborCell, gridScale, mouseWorldPos);
      
      // Calculate vortex offset for this dot
      vec2 vortexOffset = getVortexOffset(originalDotPos, time, blend);
      
      // Final dot position
      vec2 finalDotPos = originalDotPos + vortexOffset;
      
      // Distance from current pixel to the dot
      vec2 toDot = (worldPosition - finalDotPos) * gridScale;
      float distanceToDot = length(toDot);
      
      // Render a perfect circle
      float innerRadius = DOT_SIZE * 0.011;
      float outerRadius = innerRadius + 0.011;
      
      outputIntensity = max(outputIntensity, 1.0 - smoothstep(innerRadius, outerRadius, distanceToDot));
    }
  }
  
  return outputIntensity;
}

// ============================================================================
// FLOOR INTENSITY
// ============================================================================

float calculatePipelineFloorIntensity(FloorHit floorHit, vec2 mouseWorldPos, float time, float blend) {
  // Render dots with vortex effect
  float dotPattern = renderVortexDotGrid(floorHit.position.xz, DOT_GRID_SCALE, mouseWorldPos, time, blend);
  
  // Letter path fades out when vortex is active
  float letterPattern = renderLetterPath(floorHit.position.xz, DOT_GRID_SCALE, mouseWorldPos, time) * (1.0 - blend);
  float combinedPattern = max(dotPattern, letterPattern);
  
  // Standard lighting
  vec3 surfaceNormal = calculateWaveNormal(floorHit.position.xz, time);
  vec3 lightDirection = normalize(vec3(-0.35, 0.75, -0.25));
  float diffuseLight = clamp(dot(surfaceNormal, lightDirection), 0.0, 1.0);
  
  float slopeAmount = 1.0 - surfaceNormal.y;
  float ridgeHighlight = smoothstep(0.10, 0.55, slopeAmount);
  float distanceFade = exp(-0.045 * floorHit.distance);
  
  float outputIntensity = combinedPattern * (0.35 + 0.65 * diffuseLight);
  outputIntensity *= (0.70 + 0.80 * ridgeHighlight);
  outputIntensity *= distanceFade;
  
  return outputIntensity;
}
