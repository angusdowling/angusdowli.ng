import { useRef, useMemo } from "react";
import vertexShader from "./shaders/vertex.glsl";
import fragmentShaderLite from "./shaders/fragment.glsl";
import fragmentShaderFull from "./shaders/fragment-full.glsl";
import {
  useAnimationFrame,
  useSmoothMouse,
  useWebGLProgram,
  useCanvasResize,
  useCanvasVisibility,
} from "./hooks";
import { useShader } from "../../context";

const UNIFORM_NAMES = [
  "iResolution",
  "iTime",
  "iMouse",
  "iProjectIndex",
  "iProjectTime",
  "iTransitionProgress",
  "iPreviousProject",
];

interface ShaderBackgroundProps {
  className?: string;
  debug?: boolean;
  /** Resolution scale for performance. 0.5 = half res (4x faster), 1.0 = full */
  resolutionScale?: number;
}

export function ShaderBackground({
  className = "",
  debug = false,
  resolutionScale = 0.6,
}: ShaderBackgroundProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const { getShaderState } = useShader();

  const uniformNames = useMemo(() => UNIFORM_NAMES, []);

  // Platform-based shader selection:
  // - Windows/Direct3D: lite shader only (full shader compilation is too slow)
  // - Everything else (macOS, Linux, etc.): full shader with all project effects
  const { gl, program, uniforms, isWindowsANGLE } = useWebGLProgram(
    canvasRef,
    vertexShader,
    fragmentShaderLite,
    uniformNames,
    fragmentShaderFull
  );

  useCanvasResize(canvasRef, gl, resolutionScale);

  const isVisible = useCanvasVisibility(canvasRef, {
    threshold: 0.01,
    rootMargin: "100px",
  });

  const mouse = useSmoothMouse({
    smoothing: 16,
    flipY: true,
    scaleToDpr: true,
    resolutionScale,
    canvasRef,
  });

  useAnimationFrame(
    ({ time, deltaTime }) => {
      const canvas = canvasRef.current;
      if (!gl || !program || !canvas) return;

      const mousePos = mouse.update(deltaTime);
      const shaderState = getShaderState(time);

      gl.useProgram(program);
      gl.uniform2f(uniforms.iResolution, canvas.width, canvas.height);
      gl.uniform1f(uniforms.iTime, time);
      gl.uniform4f(uniforms.iMouse, mousePos.x, mousePos.y, 1, 0);

      gl.uniform1f(uniforms.iProjectIndex, shaderState.projectIndex);
      gl.uniform1f(uniforms.iProjectTime, shaderState.projectTime);
      gl.uniform1f(
        uniforms.iTransitionProgress,
        shaderState.transitionProgress
      );
      gl.uniform1f(uniforms.iPreviousProject, shaderState.previousProject);

      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    },
    { debug, paused: !isVisible }
  );

  return (
    <>
      <canvas ref={canvasRef} className={className} />
      {debug && (
        <div
          style={{
            position: "fixed",
            top: 10,
            right: 10,
            background: "rgba(0,0,0,0.7)",
            color: isWindowsANGLE ? "#ff4" : "#4f4",
            padding: "4px 8px",
            borderRadius: 4,
            fontSize: 12,
            fontFamily: "monospace",
            zIndex: 9999,
          }}
        >
          {isWindowsANGLE ? "⚡ Lite shader (Windows)" : "✓ Full shader"}
        </div>
      )}
    </>
  );
}
