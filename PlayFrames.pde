import java.nio.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import queasycam.*;
import ComputationalGeometry.*;

enum RenderMode {
  POINTS,
  CUSTOM
}

enum RenderStyle {
  POINTS,
  LINES,
  TRIANGLES,
  CUBES
}

PGL pgl;
PShader sh;

QueasyCam cam2;

ControlFrame cf;

RenderMode renderMode = RenderMode.CUSTOM;
RenderStyle renderStyle = RenderStyle.POINTS;
boolean showAxises = false;

// transformations
int zval = 250;
float scaleVal = 220;

boolean didPositionWindow = false;

int POINTS_PER_FRAME = 512 * 424;
int frameCounter = 0; // frame counter
int f = 0;

// Scene configs
Scene scene;
String SCENE_NAME = "20190405_181008_100-199";
// String SCENE_NAME = "20190405_152131_300-400";
// String SCENE_NAME = "20190405_133939";
int MAX_NUM_FRAMES = 1;
int FRAME_OFFSET = 0;
ArrayList<FloatBuffer> frames;
boolean hasLoadedFrames = false;

// Point filters
int takeEvery = 1;

// VBO buffer location in the GPU
int vertexVboId;
int vertLoc;

// Image resources
PImage bg;

// Colors
color WHITE_SMOKE = color(246, 245, 239);
color EGG_SHELL = color(244, 241, 232);
color ORANGE = color(235, 129, 44);
color TURQUOISE = color(86, 198, 202);
color DARK_TURQUOISE = color(26, 61, 56);

// Recording
Recorder rec;

/**
 * Settings
 */
void settings() {
  size(1280, 720, P3D);
}

/**
 * Setup
 */
void setup() {
  surface.setLocation(310, 10);
  frameRate(25);

  sh = loadShader("frag.glsl", "vert.glsl");
  sh.set("u_resolution", (float) width, (float) height);

  PGL pgl = beginPGL();

  IntBuffer intBuffer = IntBuffer.allocate(1);
  pgl.genBuffers(1, intBuffer);

  // memory location of the VBO
  vertexVboId = intBuffer.get(0);

  endPGL();

  bg = loadImage("img/bg1.png");

  // Load scene frames
  frames = new ArrayList<FloatBuffer>();

  // Scene configs
  scene = new Scene(SCENE_NAME);

  // Camera
  cam2 = new QueasyCam(this);
  cam2.sensitivity = 0;
  resetCamera();

  rec = new Recorder();

  // Controls
  cf = new ControlFrame(this, 280, 700, "Controls", scene);
}

void loadFrames() {
  File f = dataFile(SCENE_NAME);
  String[] names = f.list();
  Arrays.sort(names);
  printArray(names);

  int numFrames = MAX_NUM_FRAMES > 0
    ? Math.min(MAX_NUM_FRAMES, names.length - FRAME_OFFSET)
    : names.length;

  for (int i = FRAME_OFFSET; i < FRAME_OFFSET + numFrames; i++) {
    FloatBuffer frame = loadOBJFrame(SCENE_NAME, names[i], PointFilter.REMOVE_ORIGOS);
    frames.add(frame);
  }
}

void draw() {
  if (hasLoadedFrames == false) {
    loadFrames();
    hasLoadedFrames = true;

    // Enable controls
    cf.setEnabled(true);
    scene.setListening(true);
  }

  int frameId = f % frames.size();

  sh.set("u_time", millis() / 1000.0);

  if (didPositionWindow == false) {
    frame.setLocation(displayWidth - width, 0);
    didPositionWindow = true;
  }

  // background(bg);
  background(lerpColor(color(0, 0, 0), DARK_TURQUOISE, 0.2));

  // Move camera
  PVector cameraPos = cam2.position.copy();
  PVector dollyMovement = scene.dolly.direction.copy().mult(scene.dolly.speed);
  cameraPos.add(dollyMovement);
  cam2.position = cameraPos;

  // Draw axises
  if (showAxises) {
    stroke(255, 0, 0);
    line(0, 0, 0, 300, 0, 0);
    stroke(0, 255, 0);
    line(0, 0, 0, 0, 300, 0);
    stroke(0, 0, 255);
    line(0, 0, 0, 0, 0, 300);
  }

  // Get the points in 3D space
  FloatBuffer pointCloudBuffer = frames.get(frameId);

  if (mousePressed == false) {
    lights();
    directionalLight(100, 100, 100, sin(float(f) / 10), 0, 1);
  }

  if (renderMode == RenderMode.POINTS) {
    renderPoints(pointCloudBuffer);
  } else {
    renderPolygon(pointCloudBuffer);
  }

  rec.update(frameId);

  f++;
}

void renderPolygon(FloatBuffer pointsBuffer) {
  FloatBuffer points = getFilteredPoints(pointsBuffer);
  int numPoints = points.array().length / 3;

  // shader(sh);

  // noFill();
  noStroke();

  int shapeType = POINTS;
  if (renderStyle == RenderStyle.LINES) {
    shapeType = LINES;
  } else if (renderStyle == RenderStyle.TRIANGLES) {
    shapeType = TRIANGLES;
  }
  beginShape(shapeType);

  for (int i = 0; i < numPoints; i++) {
    float x = points.get(i * 3 + 0);
    float y = points.get(i * 3 + 1);
    float z = points.get(i * 3 + 2);

    color pointColor = lerpColor(ORANGE, TURQUOISE, sin(z * scene.zColorDepth));

    if (renderStyle == RenderStyle.LINES) {
      stroke(pointColor);
    } else {
      fill(pointColor);
    }

    vertex(x, y, z);
  }

  endShape();
}

void renderPoints(FloatBuffer pointCloudBuffer) {
  // Data size, 512 x 424 x 3 (XYZ) coordinate
  int vertData = 512 * 424 * 3;

  translate(width / 2, height / 2, zval);
  scale(100, -100, 100);

  pgl = beginPGL();
  // sh.bind();

  vertLoc = pgl.getAttribLocation(sh.glProgram, "vertex");

  pgl.enableVertexAttribArray(vertLoc);

  // vertex
  {
    pgl.bindBuffer(PGL.ARRAY_BUFFER, vertexVboId);
    pgl.bufferData(PGL.ARRAY_BUFFER, Float.BYTES * vertData, pointCloudBuffer, PGL.DYNAMIC_DRAW);
    pgl.vertexAttribPointer(vertLoc, 3, PGL.FLOAT, false, Float.BYTES * 3, 0);
  }

  // unbind VBOs
  pgl.bindBuffer(PGL.ARRAY_BUFFER, 0);
  pgl.drawArrays(PGL.LINES, 0, vertData);
  pgl.disableVertexAttribArray(vertLoc);

  // sh.unbind();
  endPGL();
}

public void keyPressed() {
  if (key == '=') {
    takeEvery += 10;
  }
  if (key == '-') {
    takeEvery = Math.max(takeEvery - 10, 1);
  }

  if (key == 'm') {
    cam2.sensitivity = cam2.sensitivity == 0.0 ? 1.0 : 0.0;
  }

  if (key == 'n') {
    if (renderStyle == RenderStyle.POINTS) {
      renderStyle = RenderStyle.LINES;
    } else if (renderStyle == RenderStyle.LINES) {
      renderStyle = RenderStyle.TRIANGLES;
    } else if (renderStyle == RenderStyle.TRIANGLES) {
      renderStyle = RenderStyle.POINTS;
    }
  }

  if (key == 'x') {
    showAxises = !showAxises;
  }

  if (key == 'c') {
    resetCamera();
  }

  if (key == 'k') {
    scene.cameraPosition = cam2.position.copy();
    scene.save();
  }
  if (key == 'l') {
    println("position:");
    println(cam2.position);
    println("pan:");
    println(cam2.pan);

    println("zColorDepth: " + scene.zColorDepth);
  }
}

void keyReleased(KeyEvent event) {
  if (key == 'r' || key == 'R') {
    println("is shift: " + event.isShiftDown());
    if (rec.isRecording()) {
      rec.stopRecording();
    }
    else {
      if (event.isShiftDown()) {
        rec.startRecording(SCENE_NAME, 5000, RecordingMode.FREE);
      } else {
        rec.startRecording(SCENE_NAME, frames.size(), RecordingMode.SINGLE_ROUND);
      }
    }
  }
}

void resetCamera() {
  cam2.position = scene.cameraPosition;
  cam2.pan = scene.cameraPan;
}

FloatBuffer getFilteredPoints(FloatBuffer pointsBuffer) {
  int numPoints = pointsBuffer.array().length / 3;
  float[] filteredPoints = new float[numPoints * 3];
  int numFilteredPoints = 0;

  for (int i = 0; i < numPoints; i += 3) {
    float x = pointsBuffer.get(i * 3 + 0) * 100;
    float y = pointsBuffer.get(i * 3 + 1) * -100;
    float z = pointsBuffer.get(i * 3 + 2) * 100;

    if (
      scene.filterX.min <= x && x <= scene.filterX.max &&
      scene.filterY.min <= y && y <= scene.filterY.max &&
      scene.filterZ.min <= z && z <= scene.filterZ.max &&
      i % takeEvery == 0
    ) {
      filteredPoints[numFilteredPoints * 3 + 0] = x;
      filteredPoints[numFilteredPoints * 3 + 1] = y;
      filteredPoints[numFilteredPoints * 3 + 2] = z;

      numFilteredPoints++;
    }
  }

  FloatBuffer filteredPointsBuffer = FloatBuffer.allocate(numFilteredPoints * 3);
  for (int i = 0; i < numFilteredPoints; i++) {
    filteredPointsBuffer.put(i * 3 + 0, filteredPoints[i * 3 + 0]);
    filteredPointsBuffer.put(i * 3 + 1, filteredPoints[i * 3 + 1]);
    filteredPointsBuffer.put(i * 3 + 2, filteredPoints[i * 3 + 2]);
  }
  return filteredPointsBuffer;
}
