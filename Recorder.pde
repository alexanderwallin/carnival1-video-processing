class Recorder {
  private boolean isRecording = false;
  private boolean hasStartedRecording = false;
  private boolean isDoneRecording = false;
  private String sceneName = null;
  private int numFrames = 0;
  private int numFramesRecorded = 0;

  public Recorder() {}

  public void startRecording(String sceneName, int numFrames) {
    this.sceneName = sceneName + "_" + System.currentTimeMillis();
    this.numFrames = numFrames;
    this.isRecording = true;
    this.hasStartedRecording = false;
    this.isDoneRecording = false;
  }

  public void stopRecording() {
    this.sceneName = null;
    this.numFrames = 0;
    this.numFramesRecorded = 0;
    this.isRecording = false;
  }

  public void update(int frameId) {
    if (this.isRecording) {
      if (this.hasStartedRecording == false && frameId == 0) {
        this.hasStartedRecording = true;
      }

      if (this.hasStartedRecording == true && this.numFramesRecorded < this.numFrames) {
        String filename = String.format("frame%4s", Integer.toString(frameId)).replace(" ", "0") + ".png";
        String framePath = "recordings/" + this.sceneName + "/" + filename;

        println("Saving frame to " + framePath);

        saveFrame(framePath);

        this.numFramesRecorded++;

        if (this.numFramesRecorded == this.numFrames) {
          this.isDoneRecording = true;
        }
      }
    }
  }

  public boolean isRecording() {
    return this.isRecording;
  }

  public boolean isDoneRecording() {
    return this.isDoneRecording;
  }
}
