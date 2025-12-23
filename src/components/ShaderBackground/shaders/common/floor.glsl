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
// ============================================================================

const vec2 LETTER_A_PATH[32] = vec2[32](
  // Bottom horizontal stroke
  vec2(1.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 0.0),
  // Left leg going up
  vec2(-0.5, 1.0), vec2(-0.5, 1.0),
  // Crossbar left
  vec2(-1.0, 0.0),
  // Continue up left
  vec2(0.5, 1.0), vec2(0.5, 1.0),
  // Down to crossbar
  vec2(0.5, -1.0), vec2(0.5, -1.0), vec2(0.5, -1.0), vec2(0.5, -1.0),
  // Crossbar right
  vec2(1.0, 0.0), vec2(1.0, 0.0),
  // Right leg going up
  vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0),
  vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0), vec2(-0.5, 1.0),
  // Right leg going down
  vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0),
  vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0), vec2(-0.5, -1.0)
);

vec2 getLetterDirection(int step) {
  return LETTER_A_PATH[step - (step / 32) * 32];
}

// Render animated letter path
float renderLetterPath(vec2 worldPosition, float gridScale, vec2 mouseWorldPos, float time) {
  const float LINE_WIDTH = 0.006;
  const float LETTER_SCALE = 1.67;
  const float CYCLE_DURATION = 10.0;
  const int MAX_SEGMENTS = 32;
  const float VISIBLE_WINDOW = float(MAX_SEGMENTS) + 20.0;
  
  float cycleProgress = fract(time / CYCLE_DURATION);
  float totalTravelDistance = float(MAX_SEGMENTS) + VISIBLE_WINDOW;
  float animationHead = cycleProgress * totalTravelDistance;
  float animationTail = animationHead - VISIBLE_WINDOW;
  
  // Starting position for the letter
  vec2 startingCell = vec2(-4.0, 9.0) + vec2(-3.0, -4.0) * 1.0;
  vec2 startingWorldPos = (startingCell + 0.5) / gridScale;
  
  // Early exit if too far from letter
  float maxLetterExtent = float(MAX_SEGMENTS) * LETTER_SCALE / gridScale;
  if (length(worldPosition - startingWorldPos) > maxLetterExtent + 0.5) {
    return 0.0;
  }
  
  float outputIntensity = 0.0;
  int firstVisibleSegment = int(max(0.0, animationTail - 2.0));
  int lastVisibleSegment = int(min(float(MAX_SEGMENTS), animationHead + 2.0));
  
  // Advance to start segment
  vec2 currentCell = startingCell;
  for (int segmentIndex = 0; segmentIndex < firstVisibleSegment && segmentIndex < 35; segmentIndex++) {
    currentCell += getLetterDirection(segmentIndex) * LETTER_SCALE;
  }
  
  // Draw visible segments
  for (int loopIndex = 0; loopIndex < 35; loopIndex++) {
    int segmentIndex = firstVisibleSegment + loopIndex;
    if (segmentIndex >= lastVisibleSegment) break;
    
    vec2 segmentDirection = getLetterDirection(segmentIndex) * LETTER_SCALE;
    vec2 nextCell = currentCell + segmentDirection;
    
    vec2 segmentStart = getDotWorldPosition(currentCell, gridScale, mouseWorldPos);
    vec2 segmentEnd = getDotWorldPosition(nextCell, gridScale, mouseWorldPos);
    
    // Calculate visibility with fade in/out
    float segmentPosition = float(segmentIndex);
    float fadeInAmount = smoothstep(0.0, 2.0, animationHead - segmentPosition);
    float fadeOutAmount = smoothstep(0.0, 2.0, segmentPosition - animationTail);
    float segmentVisibility = fadeInAmount * fadeOutAmount;
    
    if (segmentVisibility > 0.01) {
      float distanceToLine = distanceToLineSegment(worldPosition, segmentStart, segmentEnd);
      float lineIntensity = 1.0 - smoothstep(LINE_WIDTH * 0.5, LINE_WIDTH, distanceToLine);
      outputIntensity = max(outputIntensity, lineIntensity * segmentVisibility * 0.35);
    }
    
    currentCell = nextCell;
  }
  
  return outputIntensity;
}

// ============================================================================
// FLOOR TRACING
// ============================================================================

struct FloorHit {
  bool hit;
  vec3 position;
  float distance;
};

FloorHit traceFloor(vec3 rayOrigin, vec3 rayDirection, float time) {
  FloorHit result;
  result.hit = false;
  result.distance = 0.0;
  
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
  
  result.hit = true;
  result.position = rayOrigin + rayDirection * rayDistance;
  result.position.y = calculateWaveHeight(result.position.xz, time);
  result.distance = rayDistance;
  
  return result;
}

