// ============================================================================
// VIDEO RENDERING PLATFORM - Project 1
// Hexagonal aperture with circular cutout
// ============================================================================

// Shape configuration
const float HEXAGON_SIZE = 0.45;
const float HEXAGON_HEIGHT = 0.25;
const float INNER_CIRCLE_SIZE = 0.15;    // Size of the circular cutout

// Rotation configuration
const float ROTATION_CYCLE = 8.0;        // Seconds per rotation cycle (less frequent)
const float ROTATION_HOLD = 0.75;        // Fraction of cycle spent holding (0-1)
const float ROTATION_SPEED = 4.0;        // Speed multiplier for rotation (higher = faster snap)
const float ROTATION_ANGLE = 0.5236;     // 30 degrees in radians (point down ↔ flat down)
const float ROTATION_ANTICIPATION = 0.12; // How much to wind back before rotating
const float ROTATION_OVERSHOOT = 0.06;   // How much to overshoot target
const float MOTION_BLUR_STRENGTH = 0.0; // Blur during rotation

// Noise cloud configuration
const float NOISE_SCALE = 0.25;          // Size of noise patterns (smaller = larger patterns)
const float NOISE_SPEED = 0.2;           // Animation speed of noise movement
const float NOISE_ROTATION_SPEED = 0.25; // How fast noise rotates around shape
const float NOISE_DENSITY_MIN = -1.25;    // Lower threshold for smoothstep (lower = more visible)
const float NOISE_DENSITY_MAX = 1.0;    // Upper threshold for smoothstep (higher = softer)
const float FRESNEL_POWER = 1.5;         // Edge glow intensity (higher = sharper edge glow)
const float FRESNEL_STRENGTH = 0.5;      // How much fresnel affects density

// Glitch configuration
const float GLITCH_INTENSITY = 0.025;
const float GLITCH_FREQUENCY = 2.0;

// Vignette configuration (density fades toward edges)
const float VIGNETTE_STRENGTH = 0.5;     // How much vignette affects density (0-1)
const float VIGNETTE_SCALE = 0.7;        // Scale of vignette (lower = tighter center focus)
const float VIGNETTE_EXPONENT = 2.5;     // Falloff curve (higher = sharper edge fade)

// Interference ripple configuration
const int RIPPLE_SOURCES = 6;            // Number of ripple source points (arranged in circle)
const int RIPPLES_PER_SOURCE = 3;        // Number of ripple waves per source
const float RIPPLE_SPEED = 0.3;          // Speed of ripple animation
const float RIPPLE_FREQUENCY = 8.0;      // How many ripple bands
const float RIPPLE_STRENGTH = 0.25;      // How much ripples affect density (0-1)
const float RIPPLE_FALLOFF = 1.5;        // How quickly ripples fade with distance

// Hexagonal tiling overlay configuration
const float HEX_TILE_SCALE = 8.0;        // Size of hex tiles (higher = smaller tiles)
const float HEX_TILE_STRENGTH = 0.15;    // How visible the hex pattern is (0-1)
const float HEX_TILE_PULSE_SPEED = 0.5;  // Speed of hex tile pulsing
const float HEX_TILE_EDGE_WIDTH = 0.08;  // Width of hex cell edges

// Enhanced glitch/interference configuration
const float HBAND_FREQUENCY = 0.15;      // How often horizontal bands appear
const float HBAND_MAGNITUDE = 0.08;      // How much horizontal bands displace
const float VBAND_FREQUENCY = 0.08;      // How often vertical bands appear  
const float VBAND_MAGNITUDE = 0.15;      // How much vertical bands displace
const float STATIC_FREQUENCY = 0.1;      // How often static bursts appear
const float STATIC_MAGNITUDE = 0.02;     // Intensity of static

// ============================================================================
// HEXAGONAL TILING
// ============================================================================

// Convert to barycentric coordinates for hexagonal tiling
vec3 cartesianToBarycentric(vec2 p) {
  return vec3(p, 0.0) * mat3(
    vec3(0.0, 1.1547005383792517, 0.0),
    vec3(1.0, 0.5773502691896257, 0.0),
    vec3(-1.0, 0.5773502691896257, 0.0)
  );
}

// Map position to hexagonal tile coordinates
vec2 getHexTileCoord(vec2 uv, out vec3 bary, out ivec2 tileIdx) {
  vec2 kHexRatio = vec2(1.5, 0.8660254037844387);
  vec2 uvClip = mod(uv + kHexRatio, 2.0 * kHexRatio) - kHexRatio;
  
  tileIdx = ivec2((uv + kHexRatio) / (2.0 * kHexRatio)) * 2;
  if (uv.x + kHexRatio.x <= 0.0) tileIdx.x -= 2;
  if (uv.y + kHexRatio.y <= 0.0) tileIdx.y -= 2;
  
  bary = cartesianToBarycentric(uvClip);
  if (bary.x > 0.0) {
    if (bary.z > 1.0) { bary += vec3(-1.0, 1.0, -2.0); tileIdx += ivec2(-1, 1); }
    else if (bary.y > 1.0) { bary += vec3(-1.0, -2.0, 1.0); tileIdx += ivec2(1, 1); }
  } else {
    if (bary.y < -1.0) { bary += vec3(1.0, 2.0, -1.0); tileIdx += ivec2(-1, -1); }
    else if (bary.z < -1.0) { bary += vec3(1.0, -1.0, 2.0); tileIdx += ivec2(1, -1); }
  }
  return vec2(bary.y * 0.5773502691896257 - bary.z * 0.5773502691896257, bary.x);
}

// Calculate hexagonal tile pattern
float calculateHexTilePattern(vec3 hitPos, float time) {
  vec2 uv = hitPos.xy * HEX_TILE_SCALE;
  
  vec3 bary;
  ivec2 tileIdx;
  vec2 localUV = getHexTileCoord(uv, bary, tileIdx);
  
  // Distance from hex cell edge
  float edgeDist = 1.0 - max(max(abs(bary.x), abs(bary.y)), abs(bary.z));
  
  // Create edge highlight
  float edge = smoothstep(0.0, HEX_TILE_EDGE_WIDTH, edgeDist);
  
  // Per-tile animation based on tile index
  float tilePhase = float(tileIdx.x * 7 + tileIdx.y * 13) * 0.1;
  float pulse = sin(time * HEX_TILE_PULSE_SPEED + tilePhase) * 0.5 + 0.5;
  
  // Combine edge pattern with pulse
  float pattern = mix(1.0, edge, pulse * HEX_TILE_STRENGTH);
  
  return pattern;
}

// ============================================================================
// ENHANCED GLITCH/INTERFERENCE
// ============================================================================

// Hash function for deterministic randomness
float hashFloat(float a, float b) {
  return fract(sin(a * 12.9898 + b * 78.233) * 43758.5453);
}

// Get enhanced interference displacement
vec2 getEnhancedInterference(vec2 uv, float time) {
  vec2 displacement = vec2(0.0);
  
  // Frame-based hash for temporal variation
  float frameHash = hashFloat(floor(time * 10.0), 0.0);
  
  // Horizontal band displacement (VHS tracking errors)
  if (frameHash < HBAND_FREQUENCY) {
    float bandY = hashFloat(floor(time * 8.0), 1.0);
    float bandHeight = hashFloat(floor(time * 9.0), 2.0) * 0.2;
    
    if (uv.y > bandY - 0.5 && uv.y < bandY - 0.5 + bandHeight) {
      float bandStrength = hashFloat(floor(time * 7.0), 3.0) * 2.0 - 1.0;
      displacement.x += bandStrength * HBAND_MAGNITUDE;
    }
  }
  
  // Vertical band displacement
  float frameHash2 = hashFloat(floor(time * 12.0), 10.0);
  if (frameHash2 < VBAND_FREQUENCY) {
    float bandTop = hashFloat(floor(time * 11.0), 11.0);
    float bandShift = (hashFloat(floor(time * 13.0), 12.0) * 2.0 - 1.0) * VBAND_MAGNITUDE;
    
    if (uv.y < bandTop - 0.5) {
      displacement.y += bandShift;
    }
  }
  
  // Static noise bursts
  float frameHash3 = hashFloat(floor(time * 15.0), 20.0);
  if (frameHash3 < STATIC_FREQUENCY) {
    float staticX = snoise(vec2(uv.y * 50.0, floor(time * 20.0)));
    displacement.x += staticX * STATIC_MAGNITUDE;
  }
  
  return displacement;
}

// ============================================================================
// KICK-DROP EASING (snappy morphing like reference)
// ============================================================================

// Gaussian impulse for smooth attack/decay
float impulse(float x, float center, float width) {
  return exp(-((x - center) * (x - center)) / (width * width));
}

// KickDrop easing with control points - matches reference shader behavior
// p0 = start (time, value), p1 = kick peak, p2 = plateau, p3 = end
float kickDropFull(float t, vec2 p0, vec2 p1, vec2 p2, vec2 p3) {
  if (t < p1.x) {
    // Attack phase - fast rise with Gaussian curve
    float attackWidth = (p1.x - p0.x) / 2.145966026289347;
    return mix(p0.y, p1.y, max(0.0, impulse(t, p1.x, attackWidth) - 0.01) / 0.99);
  } else if (t < p2.x) {
    // Plateau/hold phase - linear interpolation
    return mix(p1.y, p2.y, (t - p1.x) / (p2.x - p1.x));
  } else {
    // Decay phase - slow fall with Gaussian curve
    float decayWidth = (p3.x - p2.x) / 2.145966026289347;
    return mix(p3.y, p2.y, max(0.0, impulse(t, p2.x, decayWidth) - 0.01) / 0.99);
  }
}

// Simplified KickDrop (p1 serves as both kick and plateau start)
float kickDrop3(float t, vec2 p0, vec2 p1, vec2 p2) {
  return kickDropFull(t, p0, p1, p1, p2);
}

// ============================================================================
// INTERFERENCE RIPPLE EFFECT
// ============================================================================

// Calculate interference pattern from multiple ripple sources
float calculateInterference(vec3 hitPos, float time) {
  float sigma = 0.0;
  float sigmaWeight = 0.0;
  
  // Place ripple sources in a circle around the center
  for (int j = 0; j < RIPPLE_SOURCES; j++) {
    float sourceAngle = 6.28318 * float(j) / float(RIPPLE_SOURCES);
    vec2 sourcePos = vec2(cos(sourceAngle), sin(sourceAngle)) * HEXAGON_SIZE * 0.7;
    
    for (int i = 0; i < RIPPLES_PER_SOURCE; i++) {
      // Distance from this ripple source
      float dist = length(hitPos.xy - sourcePos) * 2.0;
      
      // Weight by inverse distance (closer = stronger influence)
      float weight = 1.0 / (dist * RIPPLE_FALLOFF + 0.1);
      
      // Phase offset per source and ripple
      float phaseOffset = float(j) / float(RIPPLE_SOURCES) + float(i) / float(RIPPLES_PER_SOURCE * RIPPLE_SOURCES);
      
      // Animated ripple wave
      float ripple = fract(dist * RIPPLE_FREQUENCY * 0.1 - time * RIPPLE_SPEED - phaseOffset);
      
      // Smooth the ripple into a wave
      ripple = sin(ripple * 6.28318) * 0.5 + 0.5;
      
      sigma += ripple * weight;
      sigmaWeight += weight;
    }
  }
  
  // Normalize and convert to density modifier
  float interference = sigma / max(sigmaWeight, 0.001);
  
  // Map to a modifier that affects density (centered around 1.0)
  return mix(1.0, interference * 2.0, RIPPLE_STRENGTH);
}

// ============================================================================
// VIGNETTE EFFECT
// ============================================================================

// Calculate vignette multiplier based on distance from shape center
float calculateVignette(vec3 hitPos) {
  // Distance from center in XY plane (normalized by hexagon size)
  float dist = length(hitPos.xy) / HEXAGON_SIZE;
  
  // Vignette falloff - 1.0 at center, fading toward edges
  float vignette = 1.0 - pow(dist * VIGNETTE_SCALE, VIGNETTE_EXPONENT);
  vignette = max(0.0, vignette);
  
  // Mix between full density and vignetted density
  return mix(1.0, vignette, VIGNETTE_STRENGTH);
}

// ============================================================================
// 3D SHAPES SDF
// ============================================================================

// 2D hexagon distance
float sdHexagon2D(vec2 p, float r) {
  const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
  p = abs(p);
  p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
  p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
  return length(p) * sign(p.y);
}

// Hexagonal prism - hexagon in XY plane, extruded along Z
float sdHexPrism(vec3 p, float h, float r) {
  float hexDist = sdHexagon2D(p.xy, r);
  float zDist = abs(p.z) - h;
  return min(max(hexDist, zDist), 0.0) + length(max(vec2(hexDist, zDist), 0.0));
}

// Cylinder along Z axis
float sdCylinder(vec3 p, float r, float h) {
  float d = length(p.xy) - r;
  float z = abs(p.z) - h;
  return min(max(d, z), 0.0) + length(max(vec2(d, z), 0.0));
}

// ============================================================================
// ROTATION TIMING (KickDrop style like reference)
// ============================================================================

// Returns vec2(rotation angle, rotation velocity for motion blur)
vec2 getHexagonRotation(float time) {
  // Normalize time to cycle progress (0-1)
  float phase = mod(time, ROTATION_CYCLE) / ROTATION_CYCLE;
  
  // Determine which half of the cycle we're in
  int interval = int(phase * 2.0); // 0 or 1
  float localPhase = fract(phase * 2.0); // 0-1 within each half
  
  // Apply speed multiplier to local phase
  localPhase = clamp(localPhase * ROTATION_SPEED, 0.0, 1.0);
  
  // KickDrop control points:
  // Fast kick with slight anticipation dip, hold, then fast return
  // p0 = start, p1 = kick peak (with anticipation overshoot), p2 = plateau end, p3 = end
  float blend = kickDropFull(
    localPhase,
    vec2(0.0, 0.0),                           // Start at 0
    vec2(0.15, 1.0 + ROTATION_OVERSHOOT),     // Quick kick to peak with overshoot
    vec2(0.25, 1.0),                          // Settle to 1.0
    vec2(0.9, 1.0)                            // Hold until near end
  );
  
  // Add anticipation (slight wind-back before the kick)
  if (localPhase < 0.1) {
    float anticipation = localPhase / 0.1;
    blend -= ROTATION_ANTICIPATION * sin(anticipation * 3.14159) * (1.0 - anticipation);
  }
  
  // Alternate direction each half-cycle
  float rotation;
  if (interval == 0) {
    // First half: point down (ROTATION_ANGLE) -> flat (0)
    rotation = ROTATION_ANGLE * (1.0 - blend);
  } else {
    // Second half: flat (0) -> point down (ROTATION_ANGLE)  
    rotation = ROTATION_ANGLE * blend;
  }
  
  // Calculate velocity for motion blur (derivative approximation)
  float nextPhase = clamp((localPhase + 0.01) * ROTATION_SPEED, 0.0, 1.0);
  float nextBlend = kickDropFull(nextPhase, vec2(0.0, 0.0), vec2(0.15, 1.0 + ROTATION_OVERSHOOT), vec2(0.25, 1.0), vec2(0.9, 1.0));
  float velocity = (nextBlend - blend) * ROTATION_ANGLE * 50.0;
  
  return vec2(rotation, velocity);
}

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
// RAY MARCHING
// ============================================================================

// Store rotation state globally for motion blur
float g_rotationVelocity = 0.0;

float getApertureSDF(vec3 p, float time) {
  // Get current rotation angle and velocity
  vec2 rotState = getHexagonRotation(time);
  float angle = rotState.x;
  g_rotationVelocity = rotState.y;
  
  // Rotate hexagon around Z axis
  float c = cos(angle);
  float s = sin(angle);
  vec3 rotatedP = vec3(
    p.x * c - p.y * s,
    p.x * s + p.y * c,
    p.z
  );
  
  // Hexagonal prism
  float hexDist = sdHexPrism(rotatedP, HEXAGON_HEIGHT, HEXAGON_SIZE);
  
  // Circular cutout (cylinder through center) - not rotated
  float cylinderDist = sdCylinder(p, INNER_CIRCLE_SIZE, HEXAGON_HEIGHT + 0.1);
  
  // Subtract cylinder from hexagon (creates the aperture hole)
  return max(hexDist, -cylinderDist);
}

// Motion blur version - samples at multiple rotation offsets
float getApertureSDF_Blurred(vec3 p, float time, float blurAmount) {
  vec2 rotState = getHexagonRotation(time);
  float baseAngle = rotState.x;
  float velocity = rotState.y;
  
  // If not moving much, just return single sample
  if (abs(velocity) < 0.1) {
    float c = cos(baseAngle);
    float s = sin(baseAngle);
    vec3 rotatedP = vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
    float hexDist = sdHexPrism(rotatedP, HEXAGON_HEIGHT, HEXAGON_SIZE);
    float cylinderDist = sdCylinder(p, INNER_CIRCLE_SIZE, HEXAGON_HEIGHT + 0.1);
    return max(hexDist, -cylinderDist);
  }
  
  // Sample at multiple rotation offsets for motion blur
  float blurOffset = velocity * blurAmount;
  float minDist = 1000.0;
  
  for (int i = -2; i <= 2; i++) {
    float angle = baseAngle + blurOffset * float(i) * 0.25;
    float c = cos(angle);
    float s = sin(angle);
    vec3 rotatedP = vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
    float hexDist = sdHexPrism(rotatedP, HEXAGON_HEIGHT, HEXAGON_SIZE);
    float cylinderDist = sdCylinder(p, INNER_CIRCLE_SIZE, HEXAGON_HEIGHT + 0.1);
    float dist = max(hexDist, -cylinderDist);
    minDist = min(minDist, dist);
  }
  
  return minDist;
}

float rayMarchAperture(vec3 rayOrigin, vec3 rayDirection, float time) {
  float totalDistance = 0.0;
  
  for (int i = 0; i < RAY_MARCH_STEPS; i++) {
    vec3 currentPoint = rayOrigin + rayDirection * totalDistance;
    float dist = getApertureSDF_Blurred(currentPoint, time, MOTION_BLUR_STRENGTH);
    
    if (dist < RAY_MARCH_THRESHOLD) {
      return totalDistance;
    }
    if (totalDistance > RAY_MARCH_MAX_DIST) {
      break;
    }
    
    totalDistance += dist * 0.8;
  }
  
  return -1.0;
}

vec3 calculateApertureNormal(vec3 p, float time) {
  const float h = 0.001;
  return normalize(vec3(
    getApertureSDF(p + vec3(h, 0.0, 0.0), time) - getApertureSDF(p - vec3(h, 0.0, 0.0), time),
    getApertureSDF(p + vec3(0.0, h, 0.0), time) - getApertureSDF(p - vec3(0.0, h, 0.0), time),
    getApertureSDF(p + vec3(0.0, 0.0, h), time) - getApertureSDF(p - vec3(0.0, 0.0, h), time)
  ));
}

// ============================================================================
// MAIN SHAPE RENDERING
// ============================================================================

float renderPipelineShape(vec2 screenUV, vec2 mouseUV, float time) {
  // Apply basic glitch offset
  float glitchOffset = getGlitchOffset(screenUV.y, time);
  vec2 glitchedUV = screenUV + vec2(glitchOffset, 0.0);
  
  // Apply enhanced interference (VHS-style displacement)
  vec2 interferenceOffset = getEnhancedInterference(screenUV, time);
  glitchedUV += interferenceOffset;
  
  vec3 cameraPosition = SHAPE_CAMERA_POSITION;
  vec3 rayDirection = normalize(vec3(glitchedUV, -SHAPE_CAMERA_FOV));
  
  float hitDistance = rayMarchAperture(cameraPosition, rayDirection, time);
  
  if (hitDistance < 0.0) {
    return 0.0;
  }
  
  vec3 hitPosition = cameraPosition + rayDirection * hitDistance;
  vec3 surfaceNormal = calculateApertureNormal(hitPosition, time);
  
  // Apply rotation to sample point for animated noise
  float rotationAngle = time * NOISE_ROTATION_SPEED;
  mat3 rotationMatrix = rotateY(rotationAngle) * rotateX(time * NOISE_ROTATION_SPEED * 0.6);
  vec3 rotatedSamplePoint = rotationMatrix * hitPosition;
  
  // Multi-octave noise for cloud density
  float noiseTime = time * NOISE_SPEED;
  float noiseCoarse = snoise3(rotatedSamplePoint * NOISE_SCALE + vec3(noiseTime, 0.0, noiseTime * 0.7));
  float noiseMedium = snoise3(rotatedSamplePoint * NOISE_SCALE * 2.0 + vec3(-noiseTime * 0.8, noiseTime * 0.5, 0.0)) * 0.5;
  float noiseFine = snoise3(rotatedSamplePoint * NOISE_SCALE * 4.0 + vec3(0.0, -noiseTime * 0.6, noiseTime * 0.4)) * 0.25;
  
  float combinedNoise = noiseCoarse + noiseMedium + noiseFine;
  float cloudDensity = smoothstep(NOISE_DENSITY_MIN, NOISE_DENSITY_MAX, combinedNoise);
  
  // Apply hexagonal tiling overlay
  float hexPattern = calculateHexTilePattern(hitPosition, time);
  cloudDensity *= hexPattern;
  
  // Apply vignette - denser in center, fading toward edges
  float vignette = calculateVignette(hitPosition);
  cloudDensity *= vignette;
  
  // Apply interference ripple pattern
  float interference = calculateInterference(hitPosition, time);
  cloudDensity *= interference;
  
  // Fresnel effect for edge glow
  float fresnelFactor = 1.0 - abs(dot(surfaceNormal, -rayDirection));
  fresnelFactor = pow(fresnelFactor, FRESNEL_POWER);
  cloudDensity = mix(cloudDensity, cloudDensity * 1.3, fresnelFactor * FRESNEL_STRENGTH);
  
  // Soften edges
  float edgeDistance = abs(getApertureSDF(hitPosition, time));
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
// FLOOR INTENSITY
// ============================================================================

float calculatePipelineFloorIntensity(FloorHit floorHit, vec2 mouseWorldPos, float time, float blend) {
  // Same as default floor, just subtle pulse effect when active
  vec2 centered = floorHit.position.xz;
  float dist = length(centered);
  
  float pulse = sin(dist * 3.0 - time * 1.5) * 0.5 + 0.5;
  float pulseEffect = pulse * 0.015 * blend;
  
  vec2 pulsedPos = floorHit.position.xz;
  if (dist > 0.01) {
    pulsedPos += (centered / dist) * pulseEffect;
  }
  
  float normalDots = renderDotGrid(floorHit.position.xz, DOT_GRID_SCALE, mouseWorldPos);
  float pulsedDots = renderDotGrid(pulsedPos, DOT_GRID_SCALE, mouseWorldPos);
  float dotPattern = mix(normalDots, pulsedDots, blend);
  
  float letterPattern = renderLetterPath(floorHit.position.xz, DOT_GRID_SCALE, mouseWorldPos, time) * (1.0 - blend);
  float combinedPattern = max(dotPattern, letterPattern);
  
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
