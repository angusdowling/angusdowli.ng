// ============================================================================
// CAMERA UTILITIES
// ============================================================================

struct Camera {
  vec3 position;
  vec3 right;
  vec3 up;
  vec3 forward;
};

Camera createFloorCamera() {
  Camera cam;
  cam.position = FLOOR_CAMERA_POSITION;
  cam.forward = normalize(FLOOR_CAMERA_TARGET - cam.position);
  cam.right = normalize(cross(vec3(0.0, 1.0, 0.0), cam.forward));
  cam.up = cross(cam.forward, cam.right);
  return cam;
}

vec3 getRayDirection(Camera cam, vec2 uv, float fov) {
  return normalize(cam.right * uv.x + cam.up * uv.y + cam.forward * fov);
}

