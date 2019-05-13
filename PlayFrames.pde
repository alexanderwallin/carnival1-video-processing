import java.nio.*;
import java.util.ArrayList;
import java.util.Arrays;

import queasycam.*;
// import controlP5.*;

enum RenderMode {
  POINTS,
  CUSTOM
}

PGL pgl;
PShader sh;

int  vertLoc;

QueasyCam cam2;

// ControlP5 cp5;
// ControlFrame cf;

RenderMode renderMode = RenderMode.CUSTOM;
boolean showAxises = false;

// transformations
float a = TWO_PI;
int zval = 250;
float scaleVal = 220;

boolean didPositionWindow = false;

int POINTS_PER_FRAME = 512 * 424;
int frameCounter = 0; // frame counter
int f = 0;

// Array where all the frames are allocated
int MAX_NUM_FRAMES = 10;
int FRAME_OFFSET = 0;
// String SCENE_NAME = "20190405_152131_300-400";
String SCENE_NAME = "20190405_133939";
ArrayList<FloatBuffer> frames;
boolean hasLoadedFrames = false;

// VBO buffer location in the GPU
int vertexVboId;

// Point filters
float filterX = 0.0;
float filterZ = 100.0;
int takeEvery = 1;

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
  size(960, 640, P3D);
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

  // Camera
  cam2 = new QueasyCam(this);
  resetCamera();

  // Controls
  // cf = new ControlFrame(this, 200, 200, "Controls");

  rec = new Recorder();
}

void draw() {
  if (hasLoadedFrames == false) {
    loadFrames();
    hasLoadedFrames = true;
  }

  int frameId = f % frames.size();

  sh.set("u_time", millis() / 1000.0);

  if (didPositionWindow == false) {
    frame.setLocation(displayWidth - width, 0);
    didPositionWindow = true;
  }

  background(bg);

  // Move camera
  PVector cameraPos = cam2.position.copy();
  cameraPos.x += 1;
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

  if (renderMode == RenderMode.POINTS) {
    renderPoints(pointCloudBuffer);
  } else {
    renderPolygon(pointCloudBuffer);
  }

  rec.update(frameId);

  f++;
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

void renderPolygon(FloatBuffer pointsBuffer) {
  ArrayList<PVector> points = new ArrayList<PVector>(POINTS_PER_FRAME);

  for (int i = 0; i < POINTS_PER_FRAME; i += 3) {
    PVector point = new PVector(
      pointsBuffer.get(i) * 100,
      pointsBuffer.get(i + 1) * -100,
      pointsBuffer.get(i + 2) * 100
    );
    if (point.z < filterZ && i % takeEvery == 0) {
    // if (point.x < filterX && point.y != 0 && point.z > filterZ) {
      // println("(" + point.x + ", " + point.y + ", " + point.z + ")");
      points.add(point);
    }
  }

  shader(sh);

  stroke(200);
  // fill(200);
  // noStroke();
  noFill();
  if (mousePressed) {
    lights();
  }
  beginShape(POINTS);

  for (int i = 0; i < points.size(); i++) {
    PVector point = points.get(i);

    // sh.set("coord", point);

    color pointColor = lerpColor(ORANGE, TURQUOISE, sin((float(f) / 100.0) + point.z / 10.0));

    // stroke(
    //   100.0 + 100.0 * sin((float) (10.0 * point.x + f * 1.0f) / 150.0),
    //   100.0 + 100.0 * sin((float) (10.0 * point.y + f * 1.0f) / 150.0),
    //   0.0 + 30.0 * sin((float) (30.0 * point.z + f * 1.0f) / 150.0)
    // );

    stroke(pointColor);

    vertex(point.x, point.y, point.z);
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
  if (key == '5') {
    filterZ += 20;
  }
  if (key == '6') {
    filterZ -= 20;
  }
  if (key == '=') {
    takeEvery += 10;
  }
  if (key == '-') {
    takeEvery = Math.max(takeEvery - 10, 1);
  }

  if (key == 'm') {
    if (renderMode == RenderMode.POINTS) {
      renderMode = RenderMode.CUSTOM;
    } else {
      renderMode = RenderMode.POINTS;
    }
  }

  if (key == 'x') {
    showAxises = !showAxises;
  }

  if (key == 'c') {
    resetCamera();
  }

  if (key == 'r') {
    if (rec.isRecording()) {
      rec.stopRecording();
    }
    else {
      rec.startRecording(SCENE_NAME, frames.size());
    }
  }

  if (key == 'l') {
    println("position:");
    println(cam2.position);
    println("pan:");
    println(cam2.pan);
    println("tilt:");
    println(cam2.tilt);
  }
}

void keyTyped() {
  // if (key == 'a') {
  //   float[] lookAt = cam.getLookAt();
  //   PVector newLookAt = new PVector(lookAt[0], lookAt[1], lookAt[2]);
  //   newLookAt.add(new PVector(-50, 0, 0));
  //   cam.lookAt(newLookAt.x, newLookAt.y, newLookAt.z);
  // }
  // if (key == 'd') {
  //   float[] lookAt = cam.getLookAt();
  //   PVector newLookAt = new PVector(lookAt[0], lookAt[1], lookAt[2]);
  //   newLookAt.add(new PVector(50, 0, 0));
  //   cam.lookAt(newLookAt.x, newLookAt.y, newLookAt.z);
  // }
  // if (key == 'w') {
  //   float[] lookAt = cam.getLookAt();
  //   PVector newLookAt = new PVector(lookAt[0], lookAt[1], lookAt[2]);
  //   newLookAt.add(new PVector(0, 0, 50));
  //   cam.lookAt(newLookAt.x, newLookAt.y, newLookAt.z);
  // }
  // if (key == 's') {
  //   float[] lookAt = cam.getLookAt();
  //   PVector newLookAt = new PVector(lookAt[0], lookAt[1], lookAt[2]);
  //   newLookAt.add(new PVector(0, 0, -50));
  //   cam.lookAt(newLookAt.x, newLookAt.y, newLookAt.z);
  // }
}

// public void mouseMoved() {
//   filterX = 500 * mouseX / width;
//   filterZ = 500 * mouseY / height;
// }

void resetCamera() {
  cam2.sensitivity = 0.5;

  if (renderMode == RenderMode.POINTS) {
    cam2.position = new PVector(511.9462, 386.57687, 283.57956);
    cam2.pan = 1.3836485;
    cam2.tilt = 0.25566342;
  }
  else if (renderMode == RenderMode.CUSTOM) {
    cam2.position = new PVector(-22.433413, -49.91769, -95.838234);
    cam2.pan = 1.3967388;
    cam2.tilt = -0.051132716;
  }
}
