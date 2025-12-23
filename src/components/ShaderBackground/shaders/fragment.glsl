#version 300 es
precision highp float;

// ============================================================================
// UNIFORMS
// ============================================================================

uniform vec2 iResolution;
uniform float iTime;
uniform vec4 iMouse;

// Project state uniforms
uniform float iProjectIndex;       // 0 = none, 1-6 = projects
uniform float iProjectTime;        // Time since project selected
uniform float iTransitionProgress; // 0-1, animated blend
uniform float iPreviousProject;    // For blending during transitions

out vec4 fragColor;

// ============================================================================
// CONSTANTS
// ============================================================================

// Visual tuning
const float DOT_GRID_SCALE = 12.0;
const float DOT_SIZE = 7.0;

// ============================================================================
// MOUSE INTERACTION TUNING
// ============================================================================

// Floor dot push - how dots on the floor react to mouse
const float MOUSE_PUSH_RADIUS = 0.8;      // Size of the push area (default: 0.8)
const float MOUSE_PUSH_STRENGTH = 0.3;    // How far dots are pushed (default: 0.3)

// Wave parameters
const float WAVE_STRENGTH = 0.75;

// Shape morphing timing
const float SHAPE_HOLD_TIME = 4.0;
const float SHAPE_TRANSITION_TIME = 1.0;
const int SHAPE_COUNT = 5;

// Camera
const vec3 FLOOR_CAMERA_POSITION = vec3(0.0, 14.0, 0.5);
const vec3 FLOOR_CAMERA_TARGET = vec3(0.0, 0.0, 1.0);
const float FLOOR_CAMERA_FOV = 1.25;

const vec3 SHAPE_CAMERA_POSITION = vec3(0.0, 0.0, 3.0);
const float SHAPE_CAMERA_FOV = 1.5;

// Rendering
const int RAY_MARCH_STEPS = 64;
const float RAY_MARCH_THRESHOLD = 0.001;
const float RAY_MARCH_MAX_DIST = 10.0;

// Colors
const float BACKGROUND_GRAY = 0.96;
const float GRAIN_DARKNESS = 0.32;

// ============================================================================
// INCLUDES - Common utilities
// ============================================================================

#include "common/noise.glsl"
#include "common/sdf.glsl"
#include "common/camera.glsl"
#include "common/floor.glsl"
#include "common/grain.glsl"

// ============================================================================
// INCLUDES - Project shaders
// ============================================================================

#include "projects/default.glsl"
#include "projects/video-pipeline.glsl"
#include "projects/content-intelligence.glsl"
#include "projects/creative-automation.glsl"

// ============================================================================
// PROJECT STATE ROUTING
// ============================================================================

// Get cloud density for a specific project index
float getProjectCloudDensity(int projectIndex, vec2 screenUV, vec2 mouseUV, float time, float projectTime, float blend) {
  if (projectIndex == 0) {
    return renderDefaultShape(screenUV, mouseUV, time);
  } else if (projectIndex == 1) {
    // Pass global time for shape continuity, projectTime for animation, blend for transition
    return renderPipelineShape(screenUV, mouseUV, time, projectTime, blend);
  } else if (projectIndex == 2) {
    // Pass global time for shape continuity, projectTime for animation, blend for transition
    return renderContentIntelligenceShape(screenUV, mouseUV, time, projectTime, blend);
  } else if (projectIndex == 3) {
    return renderCreativeAutomationShape(screenUV, mouseUV, time, projectTime, blend);
  }
  
  return renderDefaultShape(screenUV, mouseUV, time);
}

// Get floor intensity for a specific project index
float getProjectFloorIntensity(int projectIndex, FloorHit floorHit, vec2 mouseWorldPos, float time, float projectTime, float blend) {
  if (projectIndex == 0) {
    return calculateDefaultFloorIntensity(floorHit, mouseWorldPos, time);
  } else if (projectIndex == 1) {
    return calculatePipelineFloorIntensity(floorHit, mouseWorldPos, time, blend);
  } else if (projectIndex == 2) {
    return calculateContentIntelligenceFloorIntensity(floorHit, mouseWorldPos, time, blend);
  } else if (projectIndex == 3) {
    return calculateCreativeAutomationFloorIntensity(floorHit, mouseWorldPos, time, blend);
  }
  
  return calculateDefaultFloorIntensity(floorHit, mouseWorldPos, time);
}

// ============================================================================
// MAIN
// ============================================================================

void main() {
  vec2 pixelCoord = gl_FragCoord.xy;
  vec2 screenUV = (pixelCoord - 0.5 * iResolution.xy) / iResolution.y;
  vec2 mouseScreenUV = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;
  float currentTime = iTime;
  
  // Project state
  int currentProject = int(iProjectIndex);
  int previousProject = int(iPreviousProject);
  float transitionBlend = iTransitionProgress;
  float projectTime = iProjectTime;
  
  // Setup floor camera
  Camera floorCamera = createFloorCamera();
  vec3 floorRayDirection = getRayDirection(floorCamera, screenUV, FLOOR_CAMERA_FOV);
  
  // Trace floor
  FloorHit floorHit = traceFloor(floorCamera.position, floorRayDirection, currentTime);
  
  // Determine if we're actually transitioning
  bool isTransitioning = transitionBlend < 0.99 && previousProject != currentProject;
  
  // Calculate floor intensity
  float floorIntensity = 0.0;
  if (floorHit.hit) {
    vec3 mouseRayDirection = getRayDirection(floorCamera, mouseScreenUV, FLOOR_CAMERA_FOV);
    float mouseRayDistance = -floorCamera.position.y / mouseRayDirection.y;
    vec2 mouseWorldPosition = floorCamera.position.xz + mouseRayDirection.xz * mouseRayDistance;
    
    if (isTransitioning) {
      float prevFloor = getProjectFloorIntensity(previousProject, floorHit, mouseWorldPosition, currentTime, projectTime, 1.0 - transitionBlend);
      float currFloor = getProjectFloorIntensity(currentProject, floorHit, mouseWorldPosition, currentTime, projectTime, transitionBlend);
      floorIntensity = mix(prevFloor, currFloor, transitionBlend);
    } else {
      floorIntensity = getProjectFloorIntensity(currentProject, floorHit, mouseWorldPosition, currentTime, projectTime, 1.0);
    }
  }
  
  // Calculate 3D shape density
  float cloudDensity;
  if (isTransitioning) {
    float prevCloudDensity = getProjectCloudDensity(previousProject, screenUV, mouseScreenUV, currentTime, projectTime, 1.0 - transitionBlend);
    float currCloudDensity = getProjectCloudDensity(currentProject, screenUV, mouseScreenUV, currentTime, projectTime, transitionBlend);
    cloudDensity = mix(prevCloudDensity, currCloudDensity, transitionBlend);
  } else {
    cloudDensity = getProjectCloudDensity(currentProject, screenUV, mouseScreenUV, currentTime, projectTime, 1.0);
  }
  
  // Apply grain effect
  float grainIntensity = renderGrainEffect(pixelCoord, screenUV, mouseScreenUV, cloudDensity, currentTime);
  
  // Final composition
  float backgroundValue = BACKGROUND_GRAY - grainIntensity * GRAIN_DARKNESS;
  vec3 backgroundColor = vec3(backgroundValue);
  vec3 dotColor = vec3(0.0);
  
  vec3 finalColor = mix(backgroundColor, dotColor, floorIntensity);
  
  fragColor = vec4(finalColor, 1.0);
}
