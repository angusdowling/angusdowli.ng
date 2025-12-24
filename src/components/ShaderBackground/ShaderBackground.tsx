import { useRef, useMemo } from "react";
import vertexShader from "./shaders/vertex.glsl";
import fragmentShader from "./shaders/fragment.glsl";
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
  const { gl, program, uniforms } = useWebGLProgram(
    canvasRef,
    vertexShader,
    fragmentShader,
    uniformNames
  );

  useCanvasResize(canvasRef, gl, resolutionScale);

  // Pause animation when canvas is not visible (scrolled out of view)
  const isVisible = useCanvasVisibility(canvasRef, {
    threshold: 0.01,
    rootMargin: "100px", // Start animation 100px before entering viewport
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

      // Project state uniforms
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

  return <canvas ref={canvasRef} className={className} />;
}
