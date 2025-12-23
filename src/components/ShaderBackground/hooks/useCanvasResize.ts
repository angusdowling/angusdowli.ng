import { useEffect } from "react";

export function useCanvasResize(
  canvasRef: React.RefObject<HTMLCanvasElement | null>,
  gl: WebGL2RenderingContext | null,
  resolutionScale: number = 1.0
) {
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !gl) return;

    const resize = () => {
      // Apply resolution scale for performance
      // 0.5 = half resolution (4x faster), 1.0 = full resolution
      const dpr = Math.min(window.devicePixelRatio, 2) * resolutionScale;
      canvas.width = window.innerWidth * dpr;
      canvas.height = window.innerHeight * dpr;
      canvas.style.width = `${window.innerWidth}px`;
      canvas.style.height = `${window.innerHeight}px`;
      gl.viewport(0, 0, canvas.width, canvas.height);
    };

    resize();
    window.addEventListener("resize", resize);
    return () => window.removeEventListener("resize", resize);
  }, [canvasRef, gl, resolutionScale]);
}
