// ============================================================================
// FLOOR RENDERING SYSTEM
// Shared floor utilities: waves, dots, letter path, floor tracing
// ============================================================================

// ============================================================================
// OCEAN WAVES
// ============================================================================

float calculateWaveHeight(vec2 position, float time) {
  float height = 0.0;
  height += WAVE_STRENGTH * 0.40 * sin(1.25 * position.x + 1.10 * time);
  height += WAVE_STRENGTH * 0.32 * sin(1.05 * position.y - 1.35 * time + 1.2);
  height += WAVE_STRENGTH * 0.22 * sin(0.85 * (position.x + position.y) + 0.90 * time);
  height += WAVE_STRENGTH * 0.15 * sin(1.90 * length(position * vec2(0.9, 1.1)) - 1.10 * time);
  return height;
}

vec3 calculateWaveNormal(vec2 position, float time) {
  const float sampleOffset = 0.01;
  float heightCenter = calculateWaveHeight(position, time);
  float heightX = calculateWaveHeight(position + vec2(sampleOffset, 0.0), time);
  float heightZ = calculateWaveHeight(position + vec2(0.0, sampleOffset), time);
  
  vec3 tangentX = vec3(sampleOffset, heightX - heightCenter, 0.0);
  vec3 tangentZ = vec3(0.0, heightZ - heightCenter, sampleOffset);
  
  return normalize(cross(tangentZ, tangentX));
}

// ============================================================================
// DOT GRID SYSTEM
// ============================================================================

// Calculate dot position with mouse repulsion
vec2 getDotWorldPosition(vec2 cellCoord, float gridScale, vec2 mouseWorldPos) {
  vec2 dotPosition = (cellCoord + 0.5) / gridScale;
  vec2 vectorToMouse = dotPosition - mouseWorldPos;
  float distanceToMouse = length(vectorToMouse);
  
  if (distanceToMouse < MOUSE_PUSH_RADIUS && distanceToMouse > 0.001) {
    vec2 repelDirection = normalize(vectorToMouse);
    float falloffFactor = 1.0 - distanceToMouse / MOUSE_PUSH_RADIUS;
    float repelAmount = MOUSE_PUSH_STRENGTH * falloffFactor * falloffFactor * falloffFactor;
    dotPosition += repelDirection * repelAmount;
  }
  
  return dotPosition;
}

// Distance from point to line segment
float distanceToLineSegment(vec2 point, vec2 lineStart, vec2 lineEnd) {
  vec2 pa = point - lineStart;
  vec2 ba = lineEnd - lineStart;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

// Render dot grid with mouse interaction
float renderDotGrid(vec2 worldPosition, float gridScale, vec2 mouseWorldPos) {
  vec2 gridPosition = worldPosition * gridScale;
  vec2 currentCell = floor(gridPosition);
  float outputIntensity = 0.0;
  
  // Check neighboring cells for dots
  for (int offsetX = -1; offsetX <= 1; offsetX++) {
    for (int offsetY = -1; offsetY <= 1; offsetY++) {
      vec2 neighborCell = currentCell + vec2(float(offsetX), float(offsetY));
      vec2 dotCenter = getDotWorldPosition(neighborCell, gridScale, mouseWorldPos);
      
      vec2 toDot = (worldPosition - dotCenter) * gridScale;
      float distanceToDot = min(length(vec2(toDot.x, toDot.y)), length(toDot));
      
      float innerRadius = DOT_SIZE * 0.011;
      float outerRadius = innerRadius + 0.011;
      
      outputIntensity = max(outputIntensity, 1.0 - smoothstep(innerRadius, outerRadius, distanceToDot));
    }
  }
  
  return outputIntensity;
}

// ============================================================================
// LETTER "A" PATTERN
// Uses if/else instead of const array to avoid ANGLE/Windows dynamic indexing crash
// ============================================================================

vec2 getLetterDirection(int step) {
  // Use float mod for consistent cross-platform behavior
  int idx = int(mod(float(step), 32.0));
  
  // Bottom horizontal stroke (0-4)
  if (idx < 5) return vec2(1.0, 0.0);
  // Left leg going up (5-6)
  if (idx < 7) return vec2(-0.5, 1.0);
  // Crossbar left (7)
  if (idx == 7) return vec2(-1.0, 0.0);
  // Continue up left (8-9)
  if (idx < 10) return vec2(0.5, 1.0);
  // Down to crossbar (10-13)
  if (idx < 14) return vec2(0.5, -1.0);
  // Crossbar right (14-15)
  if (idx < 16) return vec2(1.0, 0.0);
  // Right leg going up (16-23)
  if (idx < 24) return vec2(-0.5, 1.0);
  // Right leg going down (24-31)
  return vec2(-0.5, -1.0);
}

// Render animated letter path
// Simplified loop structure for ANGLE/Windows compatibility
float renderLetterPath(vec2 worldPosition, float gridScale, vec2 mouseWorldPos, float time) {
  const float LINE_WIDTH = 0.006;
  const float LETTER_SCALE = 1.67;
  const float CYCLE_DURATION = 10.0;
  const float VISIBLE_WINDOW = 52.0;  // 32 + 20
  
  float cycleProgress = fract(time / CYCLE_DURATION);
  float totalTravelDistance = 84.0;  // 32 + 52
  float animationHead = cycleProgress * totalTravelDistance;
  float animationTail = animationHead - VISIBLE_WINDOW;
  
  // Starting position for the letter
  vec2 startingCell = vec2(-7.0, 5.0);
  vec2 startingWorldPos = (startingCell + 0.5) / gridScale;
  
  // Early exit if too far from letter
  float maxLetterExtent = 32.0 * LETTER_SCALE / gridScale;
  if (length(worldPosition - startingWorldPos) > maxLetterExtent + 0.5) {
    return 0.0;
  }
  
  float outputIntensity = 0.0;
  vec2 currentCell = startingCell;
  
  // Fixed iteration count for ANGLE compatibility - no variable bounds or breaks
  for (int i = 0; i < 32; i++) {
    float segmentPosition = float(i);
    
    // Calculate visibility (replaces variable loop bounds)
    float isVisible = step(animationTail - 2.0, segmentPosition) * step(segmentPosition, animationHead + 2.0);
    
    vec2 segmentDirection = getLetterDirection(i) * LETTER_SCALE;
    vec2 nextCell = currentCell + segmentDirection;
    
    // Only compute if potentially visible (but always execute to avoid divergent flow)
    vec2 segmentStart = getDotWorldPosition(currentCell, gridScale, mouseWorldPos);
    vec2 segmentEnd = getDotWorldPosition(nextCell, gridScale, mouseWorldPos);
    
    float fadeInAmount = smoothstep(0.0, 2.0, animationHead - segmentPosition);
    float fadeOutAmount = smoothstep(0.0, 2.0, segmentPosition - animationTail);
    float segmentVisibility = fadeInAmount * fadeOutAmount * isVisible;
    
    float distanceToLine = distanceToLineSegment(worldPosition, segmentStart, segmentEnd);
    float lineIntensity = 1.0 - smoothstep(LINE_WIDTH * 0.5, LINE_WIDTH, distanceToLine);
    outputIntensity = max(outputIntensity, lineIntensity * segmentVisibility * 0.35);
    
    currentCell = nextCell;
  }
  
  return outputIntensity;
}

// ============================================================================
// FLOOR TRACING
// ============================================================================

// Using float instead of bool for ANGLE/Windows compatibility
struct FloorHit {
  float hit;  // 1.0 = hit, 0.0 = no hit (bool can cause issues on some ANGLE versions)
  vec3 position;
  float distance;
};

FloorHit traceFloor(vec3 rayOrigin, vec3 rayDirection, float time) {
  FloorHit result;
  result.hit = 0.0;
  result.distance = 0.0;
  result.position = vec3(0.0);
  
  // Check if ray points toward floor
  if (rayDirection.y > -0.02) {
    return result;
  }
  
  // Initial intersection with y=0 plane
  float rayDistance = -rayOrigin.y / rayDirection.y;
  if (rayDistance < 0.0 || rayDistance > 50.0) {
    return result;
  }
  
  // Refine intersection with wave heightfield
  for (int i = 0; i < 10; i++) {
    vec3 surfacePoint = rayOrigin + rayDirection * rayDistance;
    float waveHeight = calculateWaveHeight(surfacePoint.xz, time);
    float heightDelta = waveHeight - surfacePoint.y;
    rayDistance += heightDelta / rayDirection.y;
  }
  
  result.hit = 1.0;
  result.position = rayOrigin + rayDirection * rayDistance;
  result.position.y = calculateWaveHeight(result.position.xz, time);
  result.distance = rayDistance;
  
  return result;
}

