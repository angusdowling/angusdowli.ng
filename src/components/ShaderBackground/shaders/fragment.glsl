#version 300 es
precision highp float;

// ============================================================================
// UNIFORMS
// ============================================================================

uniform vec2 iResolution;
uniform float iTime;
uniform vec4 iMouse;

// Project state uniforms (kept for API compatibility, but not used in lightweight mode)
uniform float iProjectIndex;
uniform float iProjectTime;
uniform float iTransitionProgress;
uniform float iPreviousProject;

out vec4 fragColor;

// ============================================================================
// CONSTANTS
// ============================================================================

const float DOT_GRID_SCALE = 12.0;
const float DOT_SIZE = 7.0;
const float MOUSE_PUSH_RADIUS = 0.8;
const float MOUSE_PUSH_STRENGTH = 0.3;
const float WAVE_STRENGTH = 0.75;
const float SHAPE_HOLD_TIME = 4.0;
const float SHAPE_TRANSITION_TIME = 1.0;
const int SHAPE_COUNT = 5;

const vec3 FLOOR_CAMERA_POSITION = vec3(0.0, 14.0, 0.5);
const vec3 FLOOR_CAMERA_TARGET = vec3(0.0, 0.0, 1.0);
const float FLOOR_CAMERA_FOV = 1.25;

const vec3 SHAPE_CAMERA_POSITION = vec3(0.0, 0.0, 3.0);
const float SHAPE_CAMERA_FOV = 1.5;

const int RAY_MARCH_STEPS = 32;
const float RAY_MARCH_THRESHOLD = 0.002;
const float RAY_MARCH_MAX_DIST = 8.0;

const float BACKGROUND_GRAY = 0.96;
const float GRAIN_DARKNESS = 0.32;

// ============================================================================
// INCLUDES - Only essential files for homepage
// ============================================================================

#include "common/noise.glsl"
#include "common/sdf.glsl"
#include "common/camera.glsl"
#include "common/floor.glsl"
#include "common/grain.glsl"

// Only include default project shader - skip heavy project-specific shaders
#include "projects/default.glsl"

// ============================================================================
// MAIN - Lightweight homepage rendering
// ============================================================================

void main() {
  vec2 pixelCoord = gl_FragCoord.xy;
  vec2 screenUV = (pixelCoord - 0.5 * iResolution.xy) / iResolution.y;
  vec2 mouseScreenUV = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;
  float currentTime = iTime;
  
  // Floor camera setup
  vec3 floorCameraPos = FLOOR_CAMERA_POSITION;
  vec3 camForward = normalize(FLOOR_CAMERA_TARGET - FLOOR_CAMERA_POSITION);
  vec3 camRight = normalize(cross(vec3(0.0, 1.0, 0.0), camForward));
  vec3 camUp = cross(camForward, camRight);
  vec3 floorRayDir = normalize(camRight * screenUV.x + camUp * screenUV.y + camForward * FLOOR_CAMERA_FOV);
  
  // Floor tracing
  FloorHit floorHit = traceFloor(floorCameraPos, floorRayDir, currentTime);
  
  // Floor intensity
  float floorIntensity = 0.0;
  if (floorHit.hit > 0.5) {
    vec3 mouseRayDir = normalize(camRight * mouseScreenUV.x + camUp * mouseScreenUV.y + camForward * FLOOR_CAMERA_FOV);
    float denom = mouseRayDir.y;
    denom = abs(denom) < 0.001 ? -0.001 : denom;
    float mouseRayDist = -floorCameraPos.y / denom;
    vec2 mouseWorldPos = floorCameraPos.xz + mouseRayDir.xz * mouseRayDist;
    floorIntensity = calculateDefaultFloorIntensity(floorHit, mouseWorldPos, currentTime);
  }
  
  // Shape rendering - only default shape
  float cloudDensity = renderDefaultShape(screenUV, mouseScreenUV, currentTime);
  
  // Grain effect
  float grainIntensity = renderGrainEffect(pixelCoord, screenUV, mouseScreenUV, cloudDensity, currentTime);
  
  // Final composition
  float backgroundValue = BACKGROUND_GRAY - grainIntensity * GRAIN_DARKNESS;
  vec3 finalColor = mix(vec3(backgroundValue), vec3(0.0), floorIntensity);
  
  fragColor = vec4(finalColor, 1.0);
}
