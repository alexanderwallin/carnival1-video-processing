import controlP5.*;

class Scene implements ControlListener {
  public String sceneName = null;

  private boolean isListening = false;

  public PVector cameraPosition = new PVector(0.0, 0.0, 50.0);
  public float cameraPan = PI / 2.0;

  public Range filterX = new Range(-500.0, 500.0);
  public Range filterY = new Range(-500.0, 500.0);
  public Range filterZ = new Range(-500.0, 500.0);

  public float zColorDepth = 0.1;

  public Dolly dolly = new Dolly(new PVector(0.0, 0.0, 0.0), 0.0);

  public Scene(String sceneName) {
    this.sceneName = sceneName;
    JSONObject json = this.load();
    println("json");
    println(json);

    if (json == null) {
      this.save();
    }
    else {
      this.parse(json);
    }
  }

  public Scene(String sceneName, JSONObject json) {
    this.sceneName = sceneName;
    this.parse(json);
  }

  private JSONObject load() {
    String path = "configs/" + this.sceneName + ".json";

    try {
      JSONObject json = loadJSONObject(path);
      println("did load json");
      println(json);
      return json;
    } catch (NullPointerException err) {
      println("could not load json");
      return null;
    }
  }

  private void parse(JSONObject json) {
    this.cameraPosition = new PVector(
      json.getFloat("cameraPositionX"),
      json.getFloat("cameraPositionY"),
      json.getFloat("cameraPositionZ")
    );
    this.cameraPan = json.getFloat("cameraPan");

    this.filterX = new Range(json.getFloat("filterXMin"), json.getFloat("filterXMax"));
    this.filterY = new Range(json.getFloat("filterYMin"), json.getFloat("filterYMax"));
    this.filterZ = new Range(json.getFloat("filterZMin"), json.getFloat("filterZMax"));

    this.zColorDepth = json.getFloat("zColorDepth");

    this.dolly = new Dolly(
      new PVector(
        json.getFloat("dollyDirectionX"),
        json.getFloat("dollyDirectionY"),
        json.getFloat("dollyDirectionZ")
      ),
      json.getFloat("dollySpeed")
    );

    println("parsed scene config");
  }

  public void save() {
    JSONObject json = this.getJSON();
    saveJSONObject(json, "configs/" + this.sceneName + ".json");
  }

  public Scene copy() {
    JSONObject json = this.getJSON();
    Scene copy = new Scene(this.sceneName, json);
    return copy;
  }

  private JSONObject getJSON() {
    JSONObject json = new JSONObject();

    json.setFloat("cameraPositionX", this.cameraPosition.x);
    json.setFloat("cameraPositionY", this.cameraPosition.y);
    json.setFloat("cameraPositionZ", this.cameraPosition.z);
    json.setFloat("cameraPan", this.cameraPan);

    json.setFloat("filterXMin", this.filterX.min);
    json.setFloat("filterYMin", this.filterY.min);
    json.setFloat("filterZMin", this.filterZ.min);
    json.setFloat("filterXMax", this.filterX.max);
    json.setFloat("filterYMax", this.filterY.max);
    json.setFloat("filterZMax", this.filterZ.max);

    json.setFloat("zColorDepth", this.zColorDepth);

    json.setFloat("dollyDirectionX", this.dolly.direction.x);
    json.setFloat("dollyDirectionY", this.dolly.direction.y);
    json.setFloat("dollyDirectionZ", this.dolly.direction.z);
    json.setFloat("dollySpeed", this.dolly.speed);

    return json;
  }

  public void setListening(boolean isListening) {
    this.isListening = isListening;
  }

  void controlEvent(ControlEvent event) {
    if (this.isListening == false) {
      return;
    }

    Controller controller = event.getController();
    String name = controller.getName();
    println("control event: " + name);

    if (name == "z color depth") {
      this.zColorDepth = controller.getValue();
    }
    else if (name == "filter x min") {
      this.filterX.min = controller.getValue();
    }
    else if (name == "filter x max") {
      this.filterX.max = controller.getValue();
    }
    else if (name == "filter y min") {
      this.filterY.min = controller.getValue();
    }
    else if (name == "filter y max") {
      this.filterY.max = controller.getValue();
    }
    else if (name == "filter z min") {
      this.filterZ.min = controller.getValue();
    }
    else if (name == "filter z max") {
      this.filterZ.max = controller.getValue();
    }
    else if (name == "dolly x dir") {
      this.dolly.direction.x = controller.getValue();
    }
    else if (name == "dolly y dir") {
      this.dolly.direction.y = controller.getValue();
    }
    else if (name == "dolly z dir") {
      this.dolly.direction.z = controller.getValue();
    }
    else if (name == "dolly speed") {
      this.dolly.speed = controller.getValue();
    }
  }
}

