import { useEffect, useRef, useCallback } from "react";

const VERTEX_SHADER = `
  attribute vec2 a_position;
  void main() {
    gl_Position = vec4(a_position, 0.0, 1.0);
  }
`;

const FRAGMENT_SHADER = `
  precision highp float;

  uniform vec2 iResolution;
  uniform float iTime;
  uniform vec4 iMouse;

  // Simplex noise functions
  vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
  vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
  vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

  float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                        -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m; m = m*m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
  }

  // Fractal Brownian Motion for richer noise
  float fbm(vec2 p, float t) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    // Flow direction changes over time
    vec2 flow = vec2(cos(t * 0.1), sin(t * 0.15)) * t * 0.3;
    
    for (int i = 0; i < 5; i++) {
      value += amplitude * snoise(p * frequency + flow);
      amplitude *= 0.5;
      frequency *= 2.0;
      flow *= 1.2;
    }
    return value;
  }

  float waveHeight(vec2 xz, float t) {
    float h = 0.0;
    float waveStrength = 0.75;
    h += waveStrength * 0.40 * sin(1.25 * xz.x + 1.10 * t);
    h += waveStrength * 0.32 * sin(1.05 * xz.y - 1.35 * t + 1.2);
    h += waveStrength * 0.22 * sin(0.85 * (xz.x + xz.y) + 0.90 * t);
    h += waveStrength * 0.15 * sin(1.90 * length(xz * vec2(0.9, 1.1)) - 1.10 * t);
    return h;
  }

  vec3 heightNormal(vec2 xz, float t) {
    float e = 0.01;
    float h  = waveHeight(xz, t);
    float hx = waveHeight(xz + vec2(e, 0.0), t);
    float hz = waveHeight(xz + vec2(0.0, e), t);
    vec3 dx = vec3(e, hx - h, 0.0);
    vec3 dz = vec3(0.0, hz - h, e);
    return normalize(cross(dz, dx));
  }

  // Dot grid with per-dot displacement and dot-to-line morphing
  float dotGridDisplaced(vec2 xz, float scale, float dotSize, vec2 mouseWorld, float pushRadius, float pushStrength, float time) {
    vec2 g = xz * scale;
    vec2 cell = floor(g);
    
    // No morphing - dots only
    float stretch = 1.0;
    
    // Check nearby cells (dots might be pushed into our cell from neighbors)
    float result = 0.0;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        vec2 neighborCell = cell + vec2(float(dx), float(dy));
        
        // Original dot center in world space
        vec2 dotCenter = (neighborCell + 0.5) / scale;
        
        // Calculate displacement from mouse
        vec2 toMouse = dotCenter - mouseWorld;
        float distToMouse = length(toMouse);
        
        // Push dot away from mouse - very subtle gradual effect
        if (distToMouse < pushRadius && distToMouse > 0.001) {
          vec2 pushDir = normalize(toMouse);
          float falloff = 1.0 - distToMouse / pushRadius;
          // Cubic ease-out for very gradual falloff
          float pushAmount = pushStrength * falloff * falloff * falloff;
          dotCenter += pushDir * pushAmount;
        }
        
        // Distance from current position to displaced dot center
        vec2 delta = (xz - dotCenter) * scale;
        
        // For grid lines: use minimum of horizontal and vertical stretched distances
        vec2 hStretch = vec2(delta.x / stretch, delta.y);  // Horizontal line
        vec2 vStretch = vec2(delta.x, delta.y / stretch);  // Vertical line
        float hDist = length(hStretch);
        float vDist = length(vStretch);
        float distToDot = min(hDist, vDist);  // Grid = both directions
        
        // Size based on dotSize parameter (1.0 ≈ 1px)
        // Base size calibrated so dotSize in pixels maps to cell-space
        float baseSize = 0.011;  // ~1px at typical viewing distance
        float sizeFactor = stretch > 1.5 ? 0.25 : 1.0;
        float innerSize = dotSize * baseSize * sizeFactor;
        float outerSize = innerSize + baseSize;  // 1px anti-aliasing band
        
        // Render dot/line
        result = max(result, 1.0 - smoothstep(innerSize, outerSize, distToDot));
      }
    }
    return result;
  }

  void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime;

    // Mouse position in screen space
    vec2 mouseUV = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;

    // Camera
    vec3 ro = vec3(0.0, 14.0, 0.5);
    vec3 ta = vec3(0.0, 0.0, 1.0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(vec3(0.0, 1.0, 0.0), ww));
    vec3 vv = cross(ww, uu);
    vec3 rd = normalize(uu * uv.x + vv * uv.y + ww * 1.25);

    // Intersect ray with heightfield
    float T = 0.0;
    if (abs(rd.y) > 1e-4) {
      T = (0.0 - ro.y) / rd.y;
      T = max(T, 0.0);
    }
    for (int i = 0; i < 10; i++) {
      vec3 p = ro + rd * T;
      float h = waveHeight(p.xz, t);
      float dy = (h - p.y);
      T += dy / rd.y;
    }
    vec3 p = ro + rd * T;

    // Background for rays looking upward or too far
    if (T < 0.0 || T > 50.0 || rd.y > -0.02) {
      gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
      return;
    }

    // Snap to surface
    float h = waveHeight(p.xz, t);
    p.y = h;

    // Get mouse position in world XZ space
    // Cast ray from mouse to find world position
    vec3 mouseRd = normalize(uu * mouseUV.x + vv * mouseUV.y + ww * 1.25);
    float mouseT = -ro.y / mouseRd.y;
    vec2 mouseWorld = ro.xz + mouseRd.xz * mouseT;

    // Dot grid with physical displacement and morphing
    float scale = 12.0;         // Grid density (cells per world unit)
    float dotSize = 7.0;      // Dot size in pixels (1.0 ≈ 1px)
    float pushRadius = 0.8;    // World-space radius of push effect
    float pushStrength = 0.3;  // How much dots get pushed by mouse
    float dots = dotGridDisplaced(p.xz, scale, dotSize, mouseWorld, pushRadius, pushStrength, t);

    // Lighting
    vec3 n = heightNormal(p.xz, t);
    vec3 l = normalize(vec3(-0.35, 0.75, -0.25));
    float diff = clamp(dot(n, l), 0.0, 1.0);

    // Ridge highlight
    float slope = 1.0 - n.y;
    float ridge = smoothstep(0.10, 0.55, slope);

    // Distance fade
    float distFade = exp(-0.045 * T);

    // Final intensity
    float intensity = dots * (0.35 + 0.65 * diff);
    intensity *= (0.70 + 0.80 * ridge);
    intensity *= distFade;


    // 3D Sphere with rotating grain on surface
    float rotationSpeed = t * 0.15;  // Sphere rotation speed
    float orbitTime = t * 0.06;
    
    // Sphere center offset so only part is visible, drifts slowly
    vec2 sphereCenter = vec2(
      -0.4 + cos(orbitTime * 0.4) * 0.15,
      -0.3 + sin(orbitTime * 0.3) * 0.1
    );
    
    // Ray-sphere intersection for 3D effect
    vec2 toPoint = uv - sphereCenter;
    float sphereRadius = 1.2;
    float dist = length(toPoint);
    
    // Calculate density field for noise clouds (only inside sphere)
    float densityField = 0.0;
    
    if (dist <= sphereRadius) {
      // Calculate 3D position on sphere surface
      float z = sqrt(sphereRadius * sphereRadius - dist * dist);
      vec3 spherePos = vec3(toPoint.x, toPoint.y, z);
      vec3 normal = normalize(spherePos);
      
      // Convert to spherical coordinates (latitude/longitude)
      float longitude = atan(normal.x, normal.z) + rotationSpeed;  // Rotates!
      float latitude = asin(normal.y);
      
      // Map to UV on sphere surface (like a globe texture)
      vec2 sphereUV = vec2(longitude, latitude);
      
      // Layered noise for cloud/grain pattern on sphere
      // Each layer moves independently across the surface AND morphs over time
      float morphTime = t * 0.12;  // Shape evolution speed
      
      // Cloud size control (higher = bigger clouds, 1.0 = default)
      float cloudSize = 0.5;
      float cloudFreq = 0.2 / cloudSize;
      
      // Large primary cloud shapes (faster drift)
      vec2 drift1 = vec2(t * 0.05, t * 0.03);
      float cloud1 = snoise(sphereUV * cloudFreq + drift1 + vec2(sin(morphTime), cos(morphTime * 0.7)));
      
      // Secondary variation (adds some shape interest)
      vec2 drift2 = vec2(-t * 0.06, t * 0.04);
      float cloud2 = snoise(sphereUV * (cloudFreq * 1.33) + drift2 + vec2(cos(morphTime * 1.2), sin(morphTime * 0.8))) * 0.3;
      
      float cloudPattern = cloud1 + cloud2;
      
      // Lower threshold = more cloud coverage, bigger shapes
      // Wide smoothstep range = gradual feathered edges
      densityField = smoothstep(-0.65, 1.05, cloudPattern);
      
      // Edge fade for soft sphere boundary
      float edgeFade = smoothstep(sphereRadius, sphereRadius * 0.7, dist);
      densityField *= edgeFade;
    }
    
    // Grain shimmer control (0.0 = no shimmer, 1.0 = full shimmer)
    float shimmer = 0.01;
    
    float grainTime = t * 0.08;
    vec2 grainOffset = vec2(
      snoise(fragCoord * 0.01 + grainTime * 0.05),
      snoise(fragCoord * 0.01 + 100.0 + grainTime * 0.04)
    ) * shimmer;
    vec2 grainCoord = fragCoord + grainOffset;
    
    // Multi-scale grain for organic variation
    float grain1 = fract(sin(dot(grainCoord, vec2(12.9898, 78.233))) * 43758.5453);
    float grain2 = fract(sin(dot(grainCoord * 0.5 + 50.0, vec2(63.7264, 10.873))) * 28947.2934);
    float grain3 = fract(sin(dot(grainCoord * 2.0 + 100.0, vec2(91.2834, 45.164))) * 61532.8372);
    
    // Blend grains for varied particle sizes
    float grain = grain1 * 0.5 + grain2 * 0.3 + grain3 * 0.2;
    
    // Density controls the threshold - denser areas show more grain
    float threshold = 1.0 - densityField * 0.7;
    float stipple = smoothstep(threshold, threshold + 0.15, grain);
    
    // Soft intensity based on density
    float grainIntensity = stipple * densityField;
    
    // Clean white base with organic gray grain clouds
    float baseGray = 0.96;
    float grainDarkness = 0.28;
    float grayValue = baseGray - grainIntensity * grainDarkness;
    
    vec3 gradient = vec3(grayValue);
    
    // Apply dots on top of gradient
    vec3 dotColor = vec3(0.0);  // Black dots
    float dotOpacity = 1.0;
    vec3 col = mix(gradient, dotColor, intensity * dotOpacity);
    
    gl_FragColor = vec4(col, 1.0);
  }
`;

interface ShaderBackgroundProps {
  className?: string;
}

export function ShaderBackground({ className = "" }: ShaderBackgroundProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const glRef = useRef<WebGLRenderingContext | null>(null);
  const programRef = useRef<WebGLProgram | null>(null);
  const animationFrameRef = useRef<number>(0);
  const startTimeRef = useRef<number>(Date.now());
  const lastFrameTimeRef = useRef<number>(Date.now());

  // Target mouse position (where the mouse actually is)
  const mouseTargetRef = useRef<{ x: number; y: number }>({
    x: typeof window !== "undefined" ? window.innerWidth / 2 : 0,
    y: typeof window !== "undefined" ? window.innerHeight / 2 : 0,
  });

  // Smoothed mouse position (what we send to the shader)
  const mouseRef = useRef<{ x: number; y: number }>({
    x: typeof window !== "undefined" ? window.innerWidth / 2 : 0,
    y: typeof window !== "undefined" ? window.innerHeight / 2 : 0,
  });

  const createShader = useCallback(
    (gl: WebGLRenderingContext, type: number, source: string) => {
      const shader = gl.createShader(type);
      if (!shader) return null;

      gl.shaderSource(shader, source);
      gl.compileShader(shader);

      if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        console.error("Shader compile error:", gl.getShaderInfoLog(shader));
        gl.deleteShader(shader);
        return null;
      }

      return shader;
    },
    []
  );

  const createProgram = useCallback(
    (
      gl: WebGLRenderingContext,
      vertexShader: WebGLShader,
      fragmentShader: WebGLShader
    ) => {
      const program = gl.createProgram();
      if (!program) return null;

      gl.attachShader(program, vertexShader);
      gl.attachShader(program, fragmentShader);
      gl.linkProgram(program);

      if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        console.error("Program link error:", gl.getProgramInfoLog(program));
        gl.deleteProgram(program);
        return null;
      }

      return program;
    },
    []
  );

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const gl = canvas.getContext("webgl", {
      antialias: true,
      alpha: false,
      preserveDrawingBuffer: false,
    });

    if (!gl) {
      console.error("WebGL not supported");
      return;
    }

    glRef.current = gl;

    // Enable derivative extension for fwidth()
    gl.getExtension("OES_standard_derivatives");

    // Create shaders
    const vertexShader = createShader(gl, gl.VERTEX_SHADER, VERTEX_SHADER);
    const fragmentShader = createShader(
      gl,
      gl.FRAGMENT_SHADER,
      "#extension GL_OES_standard_derivatives : enable\n" + FRAGMENT_SHADER
    );

    if (!vertexShader || !fragmentShader) return;

    // Create program
    const program = createProgram(gl, vertexShader, fragmentShader);
    if (!program) return;

    programRef.current = program;

    // Create fullscreen quad
    const positions = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]);
    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);

    const positionLocation = gl.getAttribLocation(program, "a_position");
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

    // Get uniform locations
    const resolutionLocation = gl.getUniformLocation(program, "iResolution");
    const timeLocation = gl.getUniformLocation(program, "iTime");
    const mouseLocation = gl.getUniformLocation(program, "iMouse");

    // Resize handler
    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio, 2);
      canvas.width = window.innerWidth * dpr;
      canvas.height = window.innerHeight * dpr;
      canvas.style.width = `${window.innerWidth}px`;
      canvas.style.height = `${window.innerHeight}px`;
      gl.viewport(0, 0, canvas.width, canvas.height);
    };

    resize();
    window.addEventListener("resize", resize);

    // Initialize mouse to center of screen
    const dpr = Math.min(window.devicePixelRatio, 2);
    const centerX = (window.innerWidth / 2) * dpr;
    const centerY = (window.innerHeight / 2) * dpr;
    mouseTargetRef.current.x = centerX;
    mouseTargetRef.current.y = centerY;
    mouseRef.current.x = centerX;
    mouseRef.current.y = centerY;

    // Mouse handler - updates target position
    const handleMouseMove = (e: MouseEvent) => {
      const dpr = Math.min(window.devicePixelRatio, 2);
      mouseTargetRef.current.x = e.clientX * dpr;
      mouseTargetRef.current.y = (window.innerHeight - e.clientY) * dpr;
    };

    window.addEventListener("mousemove", handleMouseMove);

    // Animation loop
    const render = () => {
      const now = Date.now();
      const deltaTime = (now - lastFrameTimeRef.current) / 1000;
      lastFrameTimeRef.current = now;

      const time = (now - startTimeRef.current) / 1000;

      // Smooth interpolation towards target mouse position
      // Using exponential decay for smooth easing (frame-rate independent)
      const smoothing = 16.0; // Higher = faster, lower = more floaty
      const factor = 1.0 - Math.exp(-smoothing * deltaTime);

      mouseRef.current.x +=
        (mouseTargetRef.current.x - mouseRef.current.x) * factor;
      mouseRef.current.y +=
        (mouseTargetRef.current.y - mouseRef.current.y) * factor;

      gl.useProgram(program);
      gl.uniform2f(resolutionLocation, canvas.width, canvas.height);
      gl.uniform1f(timeLocation, time);
      gl.uniform4f(
        mouseLocation,
        mouseRef.current.x,
        mouseRef.current.y,
        1.0,
        0.0
      );

      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      animationFrameRef.current = requestAnimationFrame(render);
    };

    render();

    return () => {
      window.removeEventListener("resize", resize);
      window.removeEventListener("mousemove", handleMouseMove);
      cancelAnimationFrame(animationFrameRef.current);
    };
  }, [createShader, createProgram]);

  return (
    <canvas
      ref={canvasRef}
      className={className}
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        width: "100%",
        height: "100%",
        zIndex: -1,
      }}
    />
  );
}
