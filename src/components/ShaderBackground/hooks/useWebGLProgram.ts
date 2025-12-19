import { useEffect, useState, useRef } from "react";

interface WebGLProgramResult {
  gl: WebGL2RenderingContext | null;
  program: WebGLProgram | null;
  uniforms: Record<string, WebGLUniformLocation | null>;
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

function setupFullscreenQuad(gl: WebGL2RenderingContext, program: WebGLProgram) {
  const positions = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]);
  const buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);

  const positionLocation = gl.getAttribLocation(program, "a_position");
  gl.enableVertexAttribArray(positionLocation);
  gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
}

export function useWebGLProgram(
  canvasRef: React.RefObject<HTMLCanvasElement | null>,
  vertexSource: string,
  fragmentSource: string,
  uniformNames: string[]
): WebGLProgramResult {
  const [result, setResult] = useState<WebGLProgramResult>({
    gl: null,
    program: null,
    uniforms: {},
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

    const vs = compileShader(gl, gl.VERTEX_SHADER, vertexSource);
    const fs = compileShader(gl, gl.FRAGMENT_SHADER, fragmentSource);
    if (!vs || !fs) return;

    const program = linkProgram(gl, vs, fs);
    if (!program) return;

    setupFullscreenQuad(gl, program);

    const uniforms: Record<string, WebGLUniformLocation | null> = {};
    for (const name of uniformNames) {
      uniforms[name] = gl.getUniformLocation(program, name);
    }

    initializedRef.current = true;
    setResult({ gl, program, uniforms });
  }, [canvasRef, vertexSource, fragmentSource, uniformNames]);

  return result;
}

