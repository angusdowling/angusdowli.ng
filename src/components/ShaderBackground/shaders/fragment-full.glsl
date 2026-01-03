#version 300 es
precision highp float;

// ============================================================================
// FULL SHADER - All projects with smooth transitions
// ============================================================================

uniform vec2 iResolution;
uniform float iTime;
uniform vec4 iMouse;
uniform float iProjectIndex;
uniform float iProjectTime;
uniform float iTransitionProgress;
uniform float iPreviousProject;

out vec4 fragColor;

// Constants
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

// Common includes
#include "common/noise.glsl"
#include "common/sdf.glsl"
#include "common/camera.glsl"
#include "common/floor.glsl"
#include "common/grain.glsl"

// All project shaders
#include "projects/default.glsl"
#include "projects/video-pipeline.glsl"
#include "projects/content-intelligence.glsl"
#include "projects/creative-automation.glsl"
#include "projects/enterprise-dam.glsl"
#include "projects/move-platform.glsl"

// ============================================================================
// Helper functions to get shape/floor for a project index
// ============================================================================

float getShapeForProject(int idx, vec2 screenUV, vec2 mouseUV, float time, float projTime, float blend) {
  if (idx == 1) return renderPipelineShape(screenUV, mouseUV, time, projTime, blend);
  if (idx == 2) return renderContentIntelligenceShape(screenUV, mouseUV, time, projTime, blend);
  if (idx == 3) return renderCreativeAutomationShape(screenUV, mouseUV, time, projTime, blend);
  if (idx == 4) return renderEnterpriseDAMShape(screenUV, mouseUV, time, projTime, blend);
  if (idx == 5) return renderMovePlatformShape(screenUV, mouseUV, time, projTime, blend);
  return renderDefaultShape(screenUV, mouseUV, time);
}

float getFloorForProject(int idx, FloorHit floorHit, vec2 mouseWorldPos, float time, float blend) {
  if (idx == 1) return calculatePipelineFloorIntensity(floorHit, mouseWorldPos, time, blend);
  if (idx == 2) return calculateContentIntelligenceFloorIntensity(floorHit, mouseWorldPos, time, blend);
  if (idx == 3) return calculateCreativeAutomationFloorIntensity(floorHit, mouseWorldPos, time, blend);
  if (idx == 4) return calculateEnterpriseDAMFloorIntensity(floorHit, mouseWorldPos, time, blend);
  if (idx == 5) return calculateMovePlatformFloorIntensity(floorHit, mouseWorldPos, time, blend);
  return calculateDefaultFloorIntensity(floorHit, mouseWorldPos, time);
}

// ============================================================================
// Main
// ============================================================================

void main() {
  vec2 pixelCoord = gl_FragCoord.xy;
  vec2 screenUV = (pixelCoord - 0.5 * iResolution.xy) / iResolution.y;
  vec2 mouseScreenUV = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;
  float currentTime = iTime;
  
  int currentProject = int(iProjectIndex);
  int previousProject = int(iPreviousProject);
  float transition = iTransitionProgress;
  float projTime = iProjectTime;
  
  // Check if we're transitioning
  float isTransitioning = (transition < 0.99 && previousProject != currentProject) ? 1.0 : 0.0;
  
  // Camera
  vec3 floorCameraPos = FLOOR_CAMERA_POSITION;
  vec3 camForward = normalize(FLOOR_CAMERA_TARGET - FLOOR_CAMERA_POSITION);
  vec3 camRight = normalize(cross(vec3(0.0, 1.0, 0.0), camForward));
  vec3 camUp = cross(camForward, camRight);
  vec3 floorRayDir = normalize(camRight * screenUV.x + camUp * screenUV.y + camForward * FLOOR_CAMERA_FOV);
  
  // Floor
  FloorHit floorHit = traceFloor(floorCameraPos, floorRayDir, currentTime);
  
  float floorIntensity = 0.0;
  if (floorHit.hit > 0.5) {
    vec3 mouseRayDir = normalize(camRight * mouseScreenUV.x + camUp * mouseScreenUV.y + camForward * FLOOR_CAMERA_FOV);
    float denom = mouseRayDir.y;
    denom = abs(denom) < 0.001 ? -0.001 : denom;
    float mouseRayDist = -floorCameraPos.y / denom;
    vec2 mouseWorldPos = floorCameraPos.xz + mouseRayDir.xz * mouseRayDist;
    
    if (isTransitioning > 0.5) {
      // Blend floor between previous and current project
      float prevFloor = getFloorForProject(previousProject, floorHit, mouseWorldPos, currentTime, 1.0 - transition);
      float currFloor = getFloorForProject(currentProject, floorHit, mouseWorldPos, currentTime, transition);
      floorIntensity = mix(prevFloor, currFloor, transition);
    } else {
      floorIntensity = getFloorForProject(currentProject, floorHit, mouseWorldPos, currentTime, 1.0);
    }
  }
  
  // Shape with transition blending
  float cloudDensity = 0.0;
  if (isTransitioning > 0.5) {
    // Blend shape between previous and current project
    float prevShape = getShapeForProject(previousProject, screenUV, mouseScreenUV, currentTime, projTime, 1.0 - transition);
    float currShape = getShapeForProject(currentProject, screenUV, mouseScreenUV, currentTime, projTime, transition);
    cloudDensity = mix(prevShape, currShape, transition);
  } else {
    cloudDensity = getShapeForProject(currentProject, screenUV, mouseScreenUV, currentTime, projTime, 1.0);
  }
  
  // Grain
  float grainIntensity = renderGrainEffect(pixelCoord, screenUV, mouseScreenUV, cloudDensity, currentTime);
  
  // Output
  float backgroundValue = BACKGROUND_GRAY - grainIntensity * GRAIN_DARKNESS;
  vec3 finalColor = mix(vec3(backgroundValue), vec3(0.0), floorIntensity);
  fragColor = vec4(finalColor, 1.0);
}
