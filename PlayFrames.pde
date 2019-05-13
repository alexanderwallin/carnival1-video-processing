import java.nio.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import queasycam.*;
// import controlP5.*;
import wblut.math.*;
import wblut.processing.*;
import wblut.core.*;
import wblut.hemesh.*;
import wblut.geom.*;
import ComputationalGeometry.*;

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
int MAX_NUM_FRAMES = -1;
int FRAME_OFFSET = 0;
// String SCENE_NAME = "20190405_152131_300-400";
// String SCENE_NAME = "20190405_133939";
String SCENE_NAME = "20190405_181008_100-199";
ArrayList<FloatBuffer> frames;
boolean hasLoadedFrames = false;

// VBO buffer location in the GPU
int vertexVboId;

// Point filters
float filterX = 0.0;
float filterZ = 300.0; // 100.0;
int takeEvery = 1;
float zColorDepth = 0.1;

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

// Meshing
WB_Render meshRenderer;

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

  meshRenderer = new WB_Render(this);
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
  // PVector cameraPos = cam2.position.copy();
  // cameraPos.x += 1;
  // cam2.position = cameraPos;

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

  // renderHull(pointCloudBuffer);

  rec.update(frameId);

  f++;
}

// void renderCustomMesh(FloatBuffer pointsBuffer) {
//   List<PVector> points = getFilteredPoints(pointsBuffer).subList(0, 3000);
//   int numPoints = points.size();

//   // Array of all vertices
//   float[][] vertices = new float[numPoints][3];
//   for (int i = 0; i < numPoints; i++) {
//     PVector point = points.get(i);
//     vertices[i][0] = point.x;
//     vertices[i][1] = point.y;
//     vertices[i][2] = point.z;
//   }

//   // Array of faces. Each face is an arry of vertex indices;
//   int index = 0;
//   int[][] faces = new int[numPoints - 21][4];

//   int numPointsPerSide = (int) Math.floor(Math.sqrt(numPoints));
//   for (int i = 0; i < numPointsPerSide; i++) {
//     for (int j = 0; j < numPointsPerSide; j++) {
//       faces[index] = new int[4];
//       faces[index][0] = i + 11 * j;
//       faces[index][1] = i + 1 + 11 * j;
//       faces[index][2] = i + 1 + 11 * (j + 1);
//       faces[index][3] = i + 11 * (j + 1);
//       index++;
//     }
//   }

//   // for (int j = 0; j < 10; j++) {
//   //   for (int i = 0; i < 10; i++) {
//   //     faces[index] = new int[4];
//   //     faces[index][0] = i + 11 * j;
//   //     faces[index][1] = i + 1 + 11 * j;
//   //     faces[index][2] = i + 1 + 11 * (j + 1);
//   //     faces[index][3] = i + 11 * (j + 1);
//   //     index++;
//   //   }
//   // }

//   HEC_FromFacelist facelistCreator = new HEC_FromFacelist()
//     .setVertices(vertices)
//     .setFaces(faces)
//     .setDuplicate(false);
//   HE_Mesh mesh = new HE_Mesh(facelistCreator);
//   mesh.validate();

//   meshRenderer.drawFaces(mesh);
// }

void renderHull(FloatBuffer pointsBuffer) {
  List<PVector> points = getFilteredPoints(pointsBuffer);
  // List<PVector> orderedPoints = findConvexHull(points);
  int numPoints = points.size();

  // PVector minVector = getMinVector(points);
  // PVector maxVector = getMaxVector(points);
  // IsoSurface surface = new IsoSurface(this, minVector, maxVector, 20);
  // for (PVector point : points) {
  //   surface.addPoint(point);
  // }

  // // Plot Voxel Space
  // noFill();
  // stroke(0,10);
  // surface.plotVoxels();

  // // Plot Surface at a Threshold
  // noStroke();
  // fill(255,255,0);
  // surface.plot((mouseX * mouseY) / 5000.0);

  // IsoSkeleton skeleton = new IsoSkeleton(this);
  // for (int i = 0; i < numPoints; i++) {
  //   for (int j = i + 1; j < numPoints; j++) {
  //     if (points.get(i).dist(points.get(j)) < 10) {
  //       skeleton.addEdge(points.get(i), points.get(j));
  //     }
  //   }
  // }

  // noStroke();
  // skeleton.plot(10.f * float(mouseX) / (2.0f*width), float(mouseY) / (2.0*height));

  IsoWrap wrap = new IsoWrap(this);
  for (PVector point : points) {
    wrap.addPt(point);
  }
  fill(255, 255, 0);
  stroke(100);
  wrap.plot();
}

void renderPolygon(FloatBuffer pointsBuffer) {
  ArrayList<PVector> points = getFilteredPoints(pointsBuffer);

  // shader(sh);

  // stroke(200);
  noFill();
  // fill(ORANGE);
  // noStroke();

  beginShape(POINTS);

  for (int i = 0; i < points.size(); i++) {
    PVector point = points.get(i);

    // sh.set("coord", point);

    // stroke(
    //   100.0 + 100.0 * sin((float) (10.0 * point.x + f * 1.0f) / 150.0),
    //   100.0 + 100.0 * sin((float) (10.0 * point.y + f * 1.0f) / 150.0),
    //   0.0 + 30.0 * sin((float) (30.0 * point.z + f * 1.0f) / 150.0)
    // );

    color pointColor = lerpColor(ORANGE, TURQUOISE, sin(point.z * zColorDepth));
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
    println("filterZ = " + filterZ);
  }
  if (key == '6') {
    filterZ -= 20;
    println("filterZ = " + filterZ);
  }
  if (key == '7') {
    zColorDepth += 0.1;
    println("zColorDepth = " + zColorDepth);
  }
  if (key == '8') {
    zColorDepth -= 0.1;
    println("zColorDepth = " + zColorDepth);
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

// public void mouseMoved() {
//   filterX = 500 * mouseX / width;
//   filterZ = 500 * mouseY / height;
// }

void resetCamera() {
  cam2.sensitivity = 0;

  if (renderMode == RenderMode.POINTS) {
    cam2.position = new PVector(511.9462, 386.57687, 283.57956);
    cam2.pan = 1.3836485;
    cam2.tilt = 0.25566342;
  }
  else if (renderMode == RenderMode.CUSTOM) {
    // cam2.position = new PVector(-3.754406, -46.437614, 10.390956);
    cam2.position = new PVector(-20.598259, 0.0, 72.86122);
    cam2.pan = PI / 2; // 1.3967388;
    cam2.tilt = 0.0; // -0.051132716;
  }
}

ArrayList<PVector> getFilteredPoints(FloatBuffer pointsBuffer) {
  int numPoints = pointsBuffer.array().length / 3;
  ArrayList<PVector> points = new ArrayList<PVector>(numPoints);

  for (int i = 0; i < numPoints; i += 3) {
    PVector point = new PVector(
      pointsBuffer.get(i) * 100,
      pointsBuffer.get(i + 1) * -100,
      pointsBuffer.get(i + 2) * 100
    );
    if (point.z < filterZ && i % takeEvery == 0) {
      points.add(point);
    }
  }

  return points;
}

// boolean comparePoints(PVector a, PVector b) {
//   if (a.x < b.x) return true;
//   if (a.x > b.x) return false;
//   if (a.y < b.y) return true;
//   if (a.y > b.y) return false;
//   if (a.z < b.z) return true;
//   if (a.z > b.z) return false;
//   return false;
// }

// PointCollection CalculateContour (List<Point> points) {
//   int numPoints = points.size()

//   // locate lower-leftmost point
//   int hull = 0;
//   int i;
//   for (i = 1 ; i < numPoints; i++) {
//     if (comparePoint(points.get(i), points.get(hull))) {
//       hull = i;
//     }
//   }

//   // wrap contour
//   int[] outIndices = new int[numPoints];
//   int endPt;
//   i = 0;
//   do {
//     outIndices[i++] = hull;
//     endPt = 0;
//     for (int j = 1 ; j < numPoints ; j++) {
//       if (hull == endPt || IsLeft(points.get(hull), points.get(endPt), points.get(j)) {
//         endPt = j;
//       }
//     }
//     hull = endPt;
//   } while (endPt != outIndices[0]);

//   // build countour points
//   var contourPoints = new PointCollection(points.Capacity);
//   int results = i;
//   for (i = 0 ; i < results ; i++) {
//     contourPoints.Add(points.get(outIndices[i]));
//   }
//   return contourPoints;
// }

PVector getMinVector(List<PVector> points) {
  PVector min = points.get(0).copy();

  for (PVector point : points) {
    if (point.x < min.x) {
      min.x = point.x;
    }
    if (point.y < min.y) {
      min.y = point.y;
    }
    if (point.z < min.z) {
      min.z = point.z;
    }
  }

  return min;
}

PVector getMaxVector(List<PVector> points) {
  PVector max = points.get(0).copy();

  for (PVector point : points) {
    if (point.x > max.x) {
      max.x = point.x;
    }
    if (point.y > max.y) {
      max.y = point.y;
    }
    if (point.z > max.z) {
      max.z = point.z;
    }
  }

  return max;
}
