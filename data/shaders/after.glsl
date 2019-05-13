#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// uniform float u_time;
uniform vec2 u_resolution;
uniform float u_time;
// uniform vec3 coord;

// varying vec3 gl;

void main() {
  vec2 q = gl_FragCoord.xy / u_resolution.xy;

  vec3 col  = vec3(0.75, 0.25, 0.5);      // ...Brightness.
  col  = col*col*(3.0-2.0*col)*1.2;                   // ...Contrast.
  col *= 0.6 + 0.6*pow( 100.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.6);  // ...Vignette.
  col *= smoothstep(.0,4.0, u_time);               // ...Fade in.
  gl_FragColor = vec4(min(sqrt(col.xyz),1.0),1.);               // ...Gamma and alpha
}
