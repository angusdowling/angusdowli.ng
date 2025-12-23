// ============================================================================
// VIDEO RENDERING PLATFORM - Rutt-Etra Style Visualization
// Scanlines displaced by "signal" - representing data flowing through pipeline
// ============================================================================

// Rutt-Etra configuration
const float SCANLINES = 40.0;           // Number of horizontal scanlines
const float LINE_WIDTH = 2.0;           // Line thickness in screen space
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
// MAIN SHAPE RENDERING
// ============================================================================

float renderPipelineShape(vec2 screenUV, vec2 mouseUV, float time) {
  // Circular mask to contain the visualization
  float dist = length(screenUV);
  float shapeMask = smoothstep(SHAPE_RADIUS, SHAPE_RADIUS * 0.7, dist);
  
  // Early exit for performance
  if (shapeMask < 0.01) {
    return 0.0;
  }
  
  // Scale UV to fit nicely in the circle
  vec2 scaledUV = screenUV / SHAPE_RADIUS;
  
  // Render Rutt-Etra visualization
  float ruttEtra = renderRuttEtra(scaledUV, time * SIGNAL_SPEED);
  
  // Apply shape mask with soft edges
  float result = ruttEtra * shapeMask;
  
  // Branchless mouse repulsion effect
  float mouseDistance = length(screenUV - mouseUV);
  const float REPEL_RADIUS = 0.35;
  const float REPEL_STRENGTH = 0.25;
  
  float repelFalloff = max(0.0, 1.0 - mouseDistance / REPEL_RADIUS);
  repelFalloff = repelFalloff * repelFalloff * repelFalloff;
  result *= 1.0 - repelFalloff * REPEL_STRENGTH;
  
  return clamp(result, 0.0, 1.0);
}

// ============================================================================
// FLOOR - HORIZONTAL SCANLINES
// Data flowing across the ground plane
// ============================================================================

// Render flowing scanlines on the floor
float renderFloorScanlines(vec2 worldPos, float time, float blend) {
  float intensity = 0.0;
  
  // Number of scanlines on the floor
  float floorLines = 30.0;
  float lineSpacing = 0.4;
  
  // Precompute constants
  float halfFloorLines = floorLines * 0.5;
  float invFloorLines = 1.0 / floorLines;
  float scaledTime = time * SIGNAL_SPEED;
  float worldPosXScaled = worldPos.x * 0.2;
  
  for (float i = 0.0; i < floorLines; i++) {
    // Line position in world space
    float lineZ = (i - halfFloorLines) * lineSpacing;
    
    // Signal displacement
    float signal = generateSignal(vec2(worldPosXScaled, i * invFloorLines), scaledTime);
    
    // Slight X offset based on signal
    float xOffset = (signal - 0.5) * 0.3 * blend;
    
    // Distance to this line
    float dist = abs(worldPos.y - lineZ - xOffset);
    
    // Line intensity with AA
    float lineWidth = 0.03 + signal * 0.02;
    float lineAlpha = 1.0 - smoothstep(0.0, lineWidth, dist);
    
    // Brightness varies with signal
    float brightness = 0.3 + signal * 0.7;
    
    intensity = max(intensity, lineAlpha * brightness);
  }
  
  return intensity;
}

// ============================================================================
// FLOOR INTENSITY
// ============================================================================

float calculatePipelineFloorIntensity(FloorHit floorHit, vec2 mouseWorldPos, float time, float blend) {
  // Blend between standard dot grid and scanline pattern
  float dotPattern = renderDotGrid(floorHit.position.xz, DOT_GRID_SCALE, mouseWorldPos);
  float scanlinePattern = renderFloorScanlines(floorHit.position.xz, time, blend);
  
  // Letter path fades out when in full pipeline mode
  float letterPattern = renderLetterPath(floorHit.position.xz, DOT_GRID_SCALE, mouseWorldPos, time) * (1.0 - blend);
  
  // Blend between dots and scanlines based on transition progress
  float basePattern = mix(dotPattern, scanlinePattern, blend * 0.7);
  float combinedPattern = max(basePattern, letterPattern);
  
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
