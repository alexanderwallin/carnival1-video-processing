import java.util.ArrayList;
import java.nio.*;
//import queasycam.*;

import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;
import peasy.test.*;

enum RenderMode {
  POINTS,
  CUSTOM
}

PGL pgl;
PShader sh;

int  vertLoc;

PeasyCam cam;

RenderMode renderMode = RenderMode.POINTS;

// transformations
float a = TWO_PI;
int zval = 250;
float scaleVal = 220;

int f = 0;

int POINTS_PER_FRAME = 512 * 424;
int numFrames =  30; // 30 frames  = 1s of recording
int frameCounter = 0; // frame counter

// Array where all the frames are allocated
ArrayList<FloatBuffer> mFrames;

// VBO buffer location in the GPU
int vertexVboId;


float filterX = 0.0;
float filterZ = 0.0;


void setup() {
  size(1024, 768, P3D);

  sh = loadShader("frag.glsl", "vert.glsl");
  sh.set("u_resolution", (float) width, (float) height);
  
  PGL pgl = beginPGL();

  IntBuffer intBuffer = IntBuffer.allocate(1);
  pgl.genBuffers(1, intBuffer);

  // memory location of the VBO
  vertexVboId = intBuffer.get(0);

  endPGL();

  mFrames = new ArrayList<FloatBuffer>();
  for (int i = 0; i < numFrames; i++) {
    FloatBuffer frame = loadOBJFrame(i);
    mFrames.add(frame);

    println(frame);
  }

  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(1000);
  cam.rotateY(PI);
  cam.lookAt(-100, 100, 450);

  frameRate(25);
}

void draw() {
  sh.set("u_time", millis() / 1000.0);
  
  background(30);

  stroke(255, 0, 0);
  line(0, 0, 0, 300, 0, 0);
  stroke(0, 255, 0);
  line(0, 0, 0, 0, 300, 0);
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, 300);

  // Translate the scene to the center
  //translate(width / 2, height / 2, zval);
  //scale(scaleVal, -1 * scaleVal, scaleVal);
  //rotate(a, 0.0f, 1.0f, 0.0f);

  // Get the points in 3D space
  FloatBuffer pointCloudBuffer = mFrames.get(f % numFrames);

  if (renderMode == RenderMode.POINTS) {
    renderPoints(pointCloudBuffer);
  } else {
    renderPolygon(pointCloudBuffer);
  }

  stroke(255, 0, 0);
  text(frameRate, 50, height - 50);

  translate(-100, 100, 450);
  fill(255,0,0);
  box(30);
  translate(0, 0, 0);

  cam.feed();

  if (f < numFrames) {
    // saveFrame();
  }

  f++;
}

void renderPolygon(FloatBuffer pointsBuffer) {
  ArrayList<PVector> points = new ArrayList<PVector>(POINTS_PER_FRAME);

  for (int i = 0; i < POINTS_PER_FRAME; i += 3) {
    PVector point = new PVector(
      pointsBuffer.get(i) * 100,
      pointsBuffer.get(i + 1) * 100,
      pointsBuffer.get(i + 2) * 100
    );
    if (point.x < filterX && point.y != 0 && point.z > filterZ) {
      // println("(" + point.x + ", " + point.y + ", " + point.z + ")");
      points.add(point);
    }
  }

  shader(sh);

  // beginShape(TRIANGLES);
  // stroke(200);
  // strokeWeight(1);
  // lights();
  noStroke();
  fill(200);
  // sphereDetail(4);
  PVector prevPoint = new PVector(0, 0, 0);

  for (int i = 0; i < points.size(); i++) {
    PVector point = points.get(i);
    // vertex(point.x, point.y, point.z);
    // line(prevPoint.x, prevPoint.y, prevPoint.z, point.x, point.y, point.z);
    pushMatrix();
    translate(point.x, point.y, point.z);
    box(0.1);
    popMatrix();
    prevPoint = point;
    // println(i);
    // println("(" + point.x + ", " + point.y + ", " + point.z + ")");
  }

  // endShape();
}

void renderPoints(FloatBuffer pointCloudBuffer) {
  // Data size, 512 x 424 x 3 (XYZ) coordinate
  int vertData = 512 * 424 * 3;

  pgl = beginPGL();
  sh.bind();

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
  pgl.drawArrays(PGL.POINTS, 0, vertData);
  pgl.disableVertexAttribArray(vertLoc);

  sh.unbind();
  endPGL();
}

public void keyPressed() {
  if (key == '1') {
    cam.rotateY(0.1);
    println(cam.getRotations()[1]);
  }
  if (key == '2') {
    cam.rotateY(0.1);
    println(cam.getRotations()[1]);
  }

  // if (key == 'z') {
  //   scaleVal += 0.1;
  //   println(scaleVal);
  // }
  // if (key == 'x') {
  //   scaleVal -= 0.1;
  //   println(scaleVal);
  // }

  if (key == 'q') {
    a += 0.1;
    println(a);
  }
  if (key == 'w') {
    a -= 0.1;
    println(a);
  }

  if (key == 'c') {
    //cam.controllable = !cam.controllable;
  }

  if (key == 'm') {
    if (renderMode == RenderMode.POINTS) {
      renderMode = RenderMode.CUSTOM;
    } else {
      renderMode = RenderMode.POINTS;
    }
  }
}

public void mouseMoved() {
  filterX = 500 * mouseX / width;
  filterZ = 500 * mouseY / height;
}
