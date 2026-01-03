import { useEffect, useState, useRef } from "react";

interface WebGLProgramResult {
  gl: WebGL2RenderingContext | null;
  program: WebGLProgram | null;
  uniforms: Record<string, WebGLUniformLocation | null>;
  isWindowsANGLE: boolean;
}

function compileShader(
  gl: WebGL2RenderingContext,
  type: number,
  source: string
): WebGLShader | null {
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
}

function linkProgram(
  gl: WebGL2RenderingContext,
  vertexShader: WebGLShader,
  fragmentShader: WebGLShader
): WebGLProgram | null {
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
}

function setupFullscreenQuad(
  gl: WebGL2RenderingContext,
  program: WebGLProgram
) {
  const positions = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]);
  const buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);

  const positionLocation = gl.getAttribLocation(program, "a_position");
  gl.enableVertexAttribArray(positionLocation);
  gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
}

function getUniforms(
  gl: WebGL2RenderingContext,
  program: WebGLProgram,
  uniformNames: string[]
): Record<string, WebGLUniformLocation | null> {
  const uniforms: Record<string, WebGLUniformLocation | null> = {};
  for (const name of uniformNames) {
    uniforms[name] = gl.getUniformLocation(program, name);
  }
  return uniforms;
}

// Detect Windows ANGLE (Direct3D) - this has slow shader compilation
function isWindowsDirectX(gl: WebGL2RenderingContext): boolean {
  const debugInfo = gl.getExtension("WEBGL_debug_renderer_info");
  if (debugInfo) {
    const renderer = gl.getParameter(
      debugInfo.UNMASKED_RENDERER_WEBGL
    ) as string;
    console.log(`[Shader] Renderer: ${renderer}`);

    // Direct3D = Windows ANGLE = slow shader compilation
    if (renderer.includes("Direct3D") || renderer.includes("D3D11")) {
      console.log("[Shader] Windows Direct3D detected - using lite shader");
      return true;
    }

    // ANGLE without Metal/Vulkan/OpenGL = probably Windows
    if (
      renderer.includes("ANGLE") &&
      !renderer.includes("Metal") &&
      !renderer.includes("Vulkan") &&
      !renderer.includes("OpenGL")
    ) {
      console.log("[Shader] Windows ANGLE detected - using lite shader");
      return true;
    }
  }

  // Fallback: check platform
  const isWindows =
    navigator.platform.toLowerCase().includes("win") ||
    navigator.userAgent.toLowerCase().includes("windows");
  if (isWindows) {
    console.log("[Shader] Windows platform - using lite shader");
    return true;
  }

  return false;
}

export function useWebGLProgram(
  canvasRef: React.RefObject<HTMLCanvasElement | null>,
  vertexSource: string,
  liteFragmentSource: string,
  uniformNames: string[],
  fullFragmentSource?: string
): WebGLProgramResult {
  const [result, setResult] = useState<WebGLProgramResult>({
    gl: null,
    program: null,
    uniforms: {},
    isWindowsANGLE: false,
  });

  const initializedRef = useRef(false);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || initializedRef.current) return;

    const gl = canvas.getContext("webgl2", {
      antialias: true,
      alpha: false,
      preserveDrawingBuffer: false,
    });

    if (!gl) {
      console.error("WebGL 2.0 not supported");
      return;
    }

    // Check if we're on Windows/Direct3D (slow shader compilation)
    const isWindows = isWindowsDirectX(gl);

    // Choose shader: lite for Windows, full for everything else
    const fragmentSource =
      isWindows || !fullFragmentSource
        ? liteFragmentSource
        : fullFragmentSource;

    const shaderType = isWindows || !fullFragmentSource ? "lite" : "full";
    console.log(`[Shader] Compiling ${shaderType} shader...`);
    const startTime = performance.now();

    const vs = compileShader(gl, gl.VERTEX_SHADER, vertexSource);
    const fs = compileShader(gl, gl.FRAGMENT_SHADER, fragmentSource);
    if (!vs || !fs) return;

    const program = linkProgram(gl, vs, fs);
    if (!program) return;

    setupFullscreenQuad(gl, program);
    const uniforms = getUniforms(gl, program, uniformNames);

    const elapsed = performance.now() - startTime;
    console.log(
      `[Shader] ${shaderType} shader ready in ${elapsed.toFixed(0)}ms`
    );

    initializedRef.current = true;

    setResult({
      gl,
      program,
      uniforms,
      isWindowsANGLE: isWindows,
    });
  }, [
    canvasRef,
    vertexSource,
    liteFragmentSource,
    fullFragmentSource,
    uniformNames,
  ]);

  return result;
}
