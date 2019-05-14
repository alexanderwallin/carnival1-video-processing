import controlP5.*;

class ControlFrame extends PApplet {
  int w;
  int h;
  PApplet parent;
  ControlP5 cp5;
  Scene scene;
  boolean isEnabled = false;

  public ControlFrame(PApplet _parent, int _w, int _h, String _name, Scene _scene) {
    super();
    this.parent = _parent;
    this.w = _w;
    this.h = _h;
    this.scene = _scene;
    PApplet.runSketch(new String[]{ this.getClass().getName() }, this);
  }

  public void settings() {
    size(this.w, this.h);
  }

  public void setup() {
    surface.setLocation(10, 10);
    this.buildGUI();
  }

  public void buildGUI() {
    this.cp5 = new ControlP5(this);

    // z color depth
    this.cp5.addSlider("z color depth")
      .addListener(this.scene)
      .setPosition(10, 10)
      .setSize(200, 30)
      .setRange(0.01, 100.0)
      .setValue(this.scene.zColorDepth)
      ;

    // Point filters
    this.cp5.addSlider("filter x min")
      .addListener(this.scene)
      .setPosition(10, 60)
      .setSize(200, 30)
      .setRange(-1000, 1000.0)
      .setValue(this.scene.filterX.min)
      ;

    this.cp5.addSlider("filter x max")
      .addListener(this.scene)
      .setPosition(10, 100)
      .setSize(200, 30)
      .setRange(-1000, 1000.0)
      .setValue(this.scene.filterX.max)
      ;

    this.cp5.addSlider("filter y min")
      .addListener(this.scene)
      .setPosition(10, 140)
      .setSize(200, 30)
      .setRange(-1000, 1000.0)
      .setValue(this.scene.filterY.min)
      ;

    this.cp5.addSlider("filter y max")
      .addListener(this.scene)
      .setPosition(10, 180)
      .setSize(200, 30)
      .setRange(-1000, 1000.0)
      .setValue(this.scene.filterY.max)
      ;

    this.cp5.addSlider("filter z min")
      .addListener(this.scene)
      .setPosition(10, 220)
      .setSize(200, 30)
      .setRange(-1000, 1000.0)
      .setValue(this.scene.filterZ.min)
      ;

    this.cp5.addSlider("filter z max")
      .addListener(this.scene)
      .setPosition(10, 260)
      .setSize(200, 30)
      .setRange(-1000, 1000.0)
      ;

    // Dolly
    this.cp5.addSlider("dolly x dir")
      .addListener(this.scene)
      .setPosition(10, 310)
      .setSize(200, 30)
      .setRange(-1.0, 1.0)
      .setValue(this.scene.dolly.direction.x)
      ;

    this.cp5.addSlider("dolly y dir")
      .addListener(this.scene)
      .setPosition(10, 350)
      .setSize(200, 30)
      .setRange(-1.0, 1.0)
      .setValue(this.scene.dolly.direction.y)
      ;

    this.cp5.addSlider("dolly z dir")
      .addListener(this.scene)
      .setPosition(10, 390)
      .setSize(200, 30)
      .setRange(-1.0, 1.0)
      .setValue(this.scene.dolly.direction.z)
      ;

    this.cp5.addSlider("dolly speed")
      .addListener(this.scene)
      .setPosition(10, 430)
      .setSize(200, 30)
      .setRange(-10.0, 10.0)
      .setValue(this.scene.dolly.speed)
      ;

    // Save button
    this.cp5.addButton("save")
      .setPosition(10, this.h - 40)
      .setSize(this.w - 20, 30)
      ;
  }

  void draw() {
    background(190);
  }

  void controlEvent(ControlEvent event) {
    if (this.isEnabled == false) {
      return;
    }

    String controllerName = event.getController().getName();

    if (controllerName == "save") {
      println("SAVE");
      this.scene.save();
    }
  }

  public void setEnabled(boolean isEnabled) {
    this.isEnabled = isEnabled;
  }
}
