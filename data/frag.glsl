#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// uniform float u_time;
// uniform vec2 u_resolution;

// varying vec4 vertColor;

void main() {
  // vec2 st = gl_FragCoord.xy / u_resolution;
  // gl_FragColor = vec4(st.x, st.y, abs(sin(u_time)), 1.0f);
  gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
}
