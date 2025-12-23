import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import { ShaderProvider } from "./context";
import { RootLayout } from "./layouts";
import "./styles/global.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <ShaderProvider>
      <BrowserRouter>
        <RootLayout />
      </BrowserRouter>
    </ShaderProvider>
  </StrictMode>
);
