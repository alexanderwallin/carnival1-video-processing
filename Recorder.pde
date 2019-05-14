enum RecordingMode {
  SINGLE_ROUND,
  FREE
}

class Recorder {
  private boolean isRecording = false;
  private boolean hasStartedRecording = false;
  private boolean isDoneRecording = false;
  private String sceneName = null;
  private RecordingMode recordingMode = RecordingMode.SINGLE_ROUND;
  private int numFrames = 0;
  private int numFramesRecorded = 0;
  private int startFrame = 0;

  public Recorder() {}

  public void startRecording(String sceneName, int numFrames, RecordingMode recordingMode) {
    this.sceneName = sceneName + "_" + System.currentTimeMillis();
    this.numFrames = numFrames;
    this.recordingMode = recordingMode;

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
      if (
        this.hasStartedRecording == false &&
        (frameId == 0 || this.recordingMode == RecordingMode.FREE)
      ) {
        this.hasStartedRecording = true;
        this.startFrame = frameCount;
      }

      if (this.hasStartedRecording == true && this.numFramesRecorded < this.numFrames) {
        String filename = String.format(
          "frame-%4s-%4s",
          Integer.toString(frameCount - this.startFrame + 1),
          Integer.toString(frameId)
        ).replace(" ", "0") + ".png";
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
