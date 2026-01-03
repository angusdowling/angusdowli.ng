// ============================================================================
// CAMERA UTILITIES
// Inlined to avoid struct returns which can be buggy on ANGLE/Windows
// ============================================================================

// Pre-computed floor camera vectors (avoiding struct return)
vec3 getFloorCameraPosition() {
  return FLOOR_CAMERA_POSITION;
}

vec3 getFloorCameraForward() {
  return normalize(FLOOR_CAMERA_TARGET - FLOOR_CAMERA_POSITION);
}

vec3 getFloorCameraRight() {
  vec3 forward = getFloorCameraForward();
  return normalize(cross(vec3(0.0, 1.0, 0.0), forward));
}

vec3 getFloorCameraUp() {
  vec3 forward = getFloorCameraForward();
  vec3 right = getFloorCameraRight();
  return cross(forward, right);
}

vec3 getFloorRayDirection(vec2 uv, float fov) {
  vec3 right = getFloorCameraRight();
  vec3 up = getFloorCameraUp();
  vec3 forward = getFloorCameraForward();
  return normalize(right * uv.x + up * uv.y + forward * fov);
}

