/*
Simple class that manager saving each FloatBuffer and writes the data into a OBJ file
*/
class FrameBuffer {

  FloatBuffer frame;

  //id of the frame
  int frameId;

  FrameBuffer(FloatBuffer f) {
    frame = clone(f);
  }

  void setFrameId(int fId) {
    frameId = fId;
  }

  /*
  Writing of the obj file,
  */
  void saveOBJFrame() {
    int vertData = 512 * 424;
    String[] points = new String[vertData];

    //Iterate through all the XYZ points
    for (int i = 0; i < vertData; i++) {
      float x =  frame.get(i*3 + 0);
      float y =  frame.get(i*3 + 1);
      float z =  frame.get(i*3 + 2);
      points[i] = "v "+x+" "+y+" "+z;
    }

    saveStrings("data/frame0"+frameId+".obj", points);
    println("Done Saving Frame "+frameId);
  }

  //Simple function that copys the FloatBuffer to another FloatBuffer
  public  FloatBuffer clone(FloatBuffer original) {
    FloatBuffer clone = FloatBuffer.allocate(original.capacity());
    original.rewind();//copy from the beginning
    clone.put(original);
    original.rewind();
    clone.flip();
    return clone;
  }
}

FloatBuffer loadOBJFrame(String sceneName, int fId, PointFilter filter) {
  String frameName = String.format("frame%4s", Integer.toString(fId)).replace(" ", "0");
  String filename = frameName + ".obj";
  return loadOBJFrame(sceneName, filename, filter);
}

FloatBuffer loadOBJFrame(String sceneName, String filename, PointFilter filter) {
  println(filename);
  String[] lines = loadStrings("data/" + sceneName + "/" + filename);
  float[][] points = new float[lines.length][3];

  int pointCount = 0;

  // println("welcome to load obj frame");
  // println("filter: " + (filter == PointFilter.REMOVE_ORIGOS));

  for (int i = 0; i < lines.length; i++) {
    String[] coordinates = split(lines[i], ' ');
    float x = float(coordinates[1]);
    float y = float(coordinates[2]);
    float z = float(coordinates[3]);

    if (filter == PointFilter.REMOVE_ORIGOS) {
      if (x == 0 && y == 0 && z == 0) {
        continue;
      }
    }

    float[] point = { x, y, z };
    points[pointCount] = point;
    pointCount++;
  }

  // println("loaded " + pointCount + " points");

  FloatBuffer frame = FloatBuffer.allocate(pointCount * 3);
  for (int i = 0; i < pointCount; i++) {
    float[] point = points[i];
    frame.put(i * 3 + 0, point[0]);
    frame.put(i * 3 + 1, point[1]);
    frame.put(i * 3 + 2, point[2]);
  }

  return frame;
}
