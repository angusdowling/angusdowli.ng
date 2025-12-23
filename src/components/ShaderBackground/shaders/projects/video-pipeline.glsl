// ============================================================================
// VIDEO RENDERING PLATFORM - Rutt-Etra Style Visualization
// Scanlines carved out of solid cloud - negative space effect
// ============================================================================

// Rutt-Etra configuration
const float SCANLINES = 40.0;           // Number of horizontal scanlines
const float LINE_WIDTH = 0.10;           // Line thickness in screen space
const float EXTRUSION = 0.35;           // How much signal displaces lines vertically
const float Y_SCALE = 0.65;             // Vertical compression of the display
const float SIGNAL_SPEED = 0.4;         // Animation speed of the signal
const float FILL_OPACITY = 0.95;        // Occlusion strength (1.0 = solid terrain)
const float PERSPECTIVE = 0.3;          // Fake perspective tilt

// Signal generation config
const float SIGNAL_SCALE = 3.0;         // Noise frequency
const float SIGNAL_OCTAVES = 3.0;       // Detail level
const float FLOW_SPEED = 0.6;           // Horizontal flow of data

// Visual tuning
const float GLOW_INTENSITY = 0.4;       // Edge glow amount
const float SHAPE_RADIUS = 0.55;        // Circular mask size

// Floor flow config  
const float DOT_FLOW_STRENGTH = 0.15;   // How much rows displace vertically (like scanline extrusion)
const float DOT_FLOW_SPEED = 0.8;       // Speed multiplier for floor animation
const float FLOOR_LINE_WIDTH = 0.008;   // Thickness of floor scanlines
const float FLOOR_LINE_GLOW = 0.012;    // Anti-aliasing / glow width
const float FLOOR_LINE_OPACITY = 0.15;  // Overall intensity of floor scanlines

// ============================================================================
// SIGNAL GENERATION
// Procedural "video signal" - represents data flowing through the pipeline
// ============================================================================

// Single signal sample (used by floor rendering)
float generateSignal(vec2 uv, float time) {
  float signal = 0.0;
  float amplitude = 1.0;
  float frequency = SIGNAL_SCALE;
  
  for (float i = 0.0; i < SIGNAL_OCTAVES; i++) {
    vec2 flowUV = uv * frequency;
    flowUV.x += time * FLOW_SPEED * (1.0 + i * 0.3);
    flowUV.y += time * 0.1;
    
    signal += snoise(flowUV) * amplitude;
    
    amplitude *= 0.5;
    frequency *= 2.0;
  }
  
  signal = signal * 0.5 + 0.5;
  
  float burst = smoothstep(0.7, 0.9, snoise(vec2(uv.y * 2.0, time * 0.5)));
  signal = mix(signal, 1.0, burst * 0.3);
  
  return signal;
}

// Optimized: compute signal and its X-derivative using analytical gradients
// Returns vec2(signal, dSignal/dx) - uses snoiseGrad for ~50% fewer noise calls
vec2 generateSignalWithGradient(vec2 uv, float time) {
  float signal = 0.0;
  float gradient = 0.0;
  float amplitude = 1.0;
  float frequency = SIGNAL_SCALE;
  
  for (float i = 0.0; i < SIGNAL_OCTAVES; i++) {
    vec2 flowUV = uv * frequency;
    flowUV.x += time * FLOW_SPEED * (1.0 + i * 0.3);
    flowUV.y += time * 0.1;
    
    // Get noise value AND analytical gradient in one call
    vec3 noiseData = snoiseGrad(flowUV);
    
    signal += noiseData.x * amplitude;
    // Scale gradient by frequency (chain rule) and amplitude
    gradient += noiseData.y * amplitude * frequency;
    
    amplitude *= 0.5;
    frequency *= 2.0;
  }
  
  signal = signal * 0.5 + 0.5;
  gradient *= 0.5; // Match the signal normalization
  
  // Burst effect
  float burstSample = snoise(vec2(uv.y * 2.0, time * 0.5));
  float burst = smoothstep(0.7, 0.9, burstSample);
  signal = mix(signal, 1.0, burst * 0.3);
  // Burst dampens gradient slightly where it's active
  gradient *= (1.0 - burst * 0.3);
  
  return vec2(signal, gradient);
}

// ============================================================================
// RUTT-ETRA RENDERING
// Back-to-front scanline rendering with occlusion (optimized)
// ============================================================================

float renderRuttEtra(vec2 screenUV, float time) {
  vec2 uv = screenUV;
  
  // Apply slight perspective tilt - lines at top appear further
  float perspectiveScale = 1.0 + uv.y * PERSPECTIVE;
  uv.x *= perspectiveScale;
  
  // Initialize with background (will be covered by scanlines)
  float intensity = 0.0;
  float occlusionMask = 0.0;
  
  // Precompute constants (hoisted from loop)
  float aaWidth = 0.015 * LINE_WIDTH;
  float halfAAWidth = aaWidth * 0.5;
  float sampleUVx = uv.x * 0.5 + 0.5;
  float invScanlines = 1.0 / SCANLINES;
  float maxDisplacement = EXTRUSION * 0.5;
  float cullMargin = aaWidth * 2.0 + 0.05;
  
  // Render back-to-front (Painter's Algorithm)
  // Start from top (furthest) to bottom (nearest)
  for (float i = SCANLINES; i >= 0.0; i--) {
    float normIndex = i * invScanlines;
    
    // Quick bounds check - skip lines that can't affect this pixel
    float baseY = (normIndex - 0.5) * Y_SCALE;
    float perspectiveFactor = 1.0 - normIndex * PERSPECTIVE * 0.5;
    float minY = (baseY - maxDisplacement) * perspectiveFactor - cullMargin;
    float maxY = (baseY + maxDisplacement) * perspectiveFactor + cullMargin;
    
    if (uv.y < minY || uv.y > maxY) continue;
    
    // Sample position for this scanline
    vec2 sampleUV = vec2(sampleUVx, normIndex);
    
    // Generate signal and analytical gradient in one pass
    vec2 signalData = generateSignalWithGradient(sampleUV, time);
    float signal = signalData.x;
    
    // Calculate the Y position of this scanline
    float lineY = baseY + (signal - 0.5) * EXTRUSION;
    lineY *= perspectiveFactor;
    
    // Distance from current pixel to this scanline
    float dist = uv.y - lineY;
    
    // Anti-aliased line rendering
    float lineAlpha = 1.0 - smoothstep(0.0, aaWidth, abs(dist));
    
    // Occlusion: if we're below this line, it covers what's behind
    float fillAlpha = 1.0 - smoothstep(0.0, halfAAWidth, dist);
    
    // Branchless occlusion (replaces if statement)
    float shouldOcclude = step(0.5, fillAlpha);
    intensity = mix(intensity, intensity * (1.0 - FILL_OPACITY), shouldOcclude);
    occlusionMask = max(occlusionMask, shouldOcclude);
    
    // Draw the line with brightness based on signal
    // Slope-based shading using analytical gradient (no extra noise calls!)
    float slope = abs(signalData.y) * 0.1;
    float lineBrightness = 0.6 + signal * 0.4 + slope * GLOW_INTENSITY;
    
    // Composite the line
    intensity = mix(intensity, lineBrightness, lineAlpha);
  }
  
  return intensity;
}

// ============================================================================
// MAIN SHAPE RENDERING - Negative Space Effect
// 3D morphing shape with Rutt-Etra scanlines carved out
// Seamless transition: uses global time for shape, blend for Rutt-Etra fade-in
// ============================================================================

float renderPipelineShape(vec2 screenUV, vec2 mouseUV, float globalTime, float projectTime, float blend) {
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
  // Uses shared CLOUD_* constants from default.glsl for sync
  float rotationAngle = globalTime * CLOUD_ROTATION_SPEED;
  mat3 rotationMatrix = rotateY(rotationAngle) * rotateX(globalTime * 0.15);
  vec3 rotatedSamplePoint = rotationMatrix * hitPosition;
  
  // Multi-octave noise (uses shared constants from default.glsl)
  float noiseTime = globalTime * CLOUD_NOISE_SPEED;
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
  
  // === RUTT-ETRA CUTOUT (fades in/out with transition) ===
  // Use globalTime for animation so it keeps moving during fade-out too
  vec2 scaledUV = screenUV / SHAPE_RADIUS;
  float ruttEtra = renderRuttEtra(scaledUV, globalTime * SIGNAL_SPEED);
  
  // Carve out scanlines - strength controlled by blend
  // blend=0 means hidden, blend=1 means full effect
  float cutoutStrength = 0.95 * blend;
  cloudDensity *= (1.0 - ruttEtra * cutoutStrength);
  
  return cloudDensity;
}

// ============================================================================
// FLOOR - RUTT-ETRA STYLE LINE GRID
// Continuous horizontal lines displaced vertically like CRT scanlines
// ============================================================================

// Calculate the displaced Y position for a scanline row at a given X coordinate
float getLineDisplacedY(float rowIndex, float worldX, float gridScale, float time) {
  float baseY = (rowIndex + 0.5) / gridScale;
  float normalizedRow = fract(rowIndex / 40.0); // Match SCANLINES count
  
  // Sample signal at this X position for this row
  float scaledTime = time * SIGNAL_SPEED * DOT_FLOW_SPEED;
  vec2 signalUV = vec2(worldX * 0.3 + scaledTime * FLOW_SPEED, normalizedRow);
  float signal = generateSignal(signalUV, scaledTime);
  
  // Displace in Y direction (depth) - creates the wavy horizontal lines
  return baseY + (signal - 0.5) * DOT_FLOW_STRENGTH;
}

// Render Rutt-Etra style continuous line grid
// Each horizontal line waves up and down based on signal - true scanline effect
float renderRuttEtraLineGrid(vec2 worldPosition, float gridScale, vec2 mouseWorldPos, float time) {
  // Find which row we're near in grid space
  float gridY = worldPosition.y * gridScale;
  float nearestRow = floor(gridY + 0.5);
  
  float outputIntensity = 0.0;
  
  // Check several rows around current position (lines can displace quite far)
  for (int rowOffset = -3; rowOffset <= 3; rowOffset++) {
    float rowIndex = nearestRow + float(rowOffset);
    
    // Get the displaced Y position of this line at our X coordinate
    float lineY = getLineDisplacedY(rowIndex, worldPosition.x, gridScale, time);
    
    // Apply mouse repulsion to the line
    vec2 linePoint = vec2(worldPosition.x, lineY);
    vec2 vectorToMouse = linePoint - mouseWorldPos;
    float distanceToMouse = length(vectorToMouse);
    
    float repelFalloff = max(0.0, 1.0 - distanceToMouse / MOUSE_PUSH_RADIUS);
    if (repelFalloff > 0.001) {
      // Repel the line away from mouse in Y direction
      float repelDir = sign(lineY - mouseWorldPos.y);
      if (abs(lineY - mouseWorldPos.y) < 0.01) repelDir = 1.0;
      lineY += repelDir * MOUSE_PUSH_STRENGTH * repelFalloff * repelFalloff * 0.5;
    }
    
    // Distance from pixel to this line
    float distToLine = abs(worldPosition.y - lineY);
    
    // Anti-aliased line rendering with slight glow
    float lineCore = 1.0 - smoothstep(0.0, FLOOR_LINE_WIDTH, distToLine);
    float lineGlow = (1.0 - smoothstep(FLOOR_LINE_WIDTH, FLOOR_LINE_WIDTH + FLOOR_LINE_GLOW, distToLine)) * 0.3;
    
    outputIntensity = max(outputIntensity, lineCore + lineGlow);
  }
  
  return outputIntensity * FLOOR_LINE_OPACITY;
}

// ============================================================================
// FLOOR INTENSITY
// ============================================================================

float calculatePipelineFloorIntensity(FloorHit floorHit, vec2 mouseWorldPos, float time, float blend) {
  // Static dot grid (default state)
  float staticDots = renderDotGrid(floorHit.position.xz, DOT_GRID_SCALE, mouseWorldPos);
  
  // Rutt-Etra style continuous lines (pipeline state) - true scanline effect
  float ruttEtraLines = renderRuttEtraLineGrid(floorHit.position.xz, DOT_GRID_SCALE, mouseWorldPos, time);
  
  // Blend between static dots and Rutt-Etra lines based on transition
  float dotPattern = mix(staticDots, ruttEtraLines, blend);
  
  // Letter path fades out when in full pipeline mode
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
