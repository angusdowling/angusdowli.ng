// ============================================================================
// GRAIN / STIPPLE EFFECT
// Creates the stippled texture overlay on the 3D shapes
// ============================================================================

float renderGrainEffect(vec2 pixelCoord, vec2 screenUV, vec2 mouseUV, float inputDensity, float time) {
  const float SHIMMER_AMOUNT = 0.015;
  float animatedTime = time * 0.08;
  
  // Animated grain offset
  vec2 grainOffset = vec2(
    snoise(pixelCoord * 0.01 + animatedTime * 0.05),
    snoise(pixelCoord * 0.01 + 100.0 + animatedTime * 0.04)
  ) * SHIMMER_AMOUNT;
  
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

