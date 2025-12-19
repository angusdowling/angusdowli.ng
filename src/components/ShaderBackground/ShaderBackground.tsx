import { useRef, useMemo } from "react";
import vertexShader from "./shaders/vertex.glsl?raw";
import fragmentShader from "./shaders/fragment.glsl?raw";
import {
  useAnimationFrame,
  useSmoothMouse,
  useWebGLProgram,
  useCanvasResize,
} from "./hooks";

const UNIFORM_NAMES = ["iResolution", "iTime", "iMouse"];

interface ShaderBackgroundProps {
  className?: string;
  debug?: boolean;
}

export function ShaderBackground({
  className = "",
  debug = false,
}: ShaderBackgroundProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const uniformNames = useMemo(() => UNIFORM_NAMES, []);
  const { gl, program, uniforms } = useWebGLProgram(
    canvasRef,
    vertexShader,
    fragmentShader,
    uniformNames
  );

  useCanvasResize(canvasRef, gl);

  const mouse = useSmoothMouse({
    smoothing: 16,
    flipY: true,
    scaleToDpr: true,
  });

  useAnimationFrame(
    ({ time, deltaTime }) => {
      const canvas = canvasRef.current;
      if (!gl || !program || !canvas) return;

      const mousePos = mouse.update(deltaTime);

      gl.useProgram(program);
      gl.uniform2f(uniforms.iResolution, canvas.width, canvas.height);
      gl.uniform1f(uniforms.iTime, time);
      gl.uniform4f(uniforms.iMouse, mousePos.x, mousePos.y, 1, 0);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    },
    { debug }
  );

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
