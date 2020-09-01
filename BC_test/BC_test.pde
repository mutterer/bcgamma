/**
 * BC_test
 * 
 * a prototype brightness and contrast adjustment user interface
 * with gamma
 * all display is done on lookup table.
 * jerome / 2020/09/01
 *
 */


import controlP5.*;
import ij.*;
import ij.process.ImageStatistics;
import ij.process.LUT;


ControlP5 cp5;
ImageStatistics is;
Chart myChart, myGamma;
int id;
int[] histo;
byte [] glut;
float[] fhisto, fgamma;

Range range;
int min = 0;
int max = 255;


void setup() {
  size(400, 200);
  ImageJ ij = new ImageJ(ImageJ.EMBEDDED);
  ij.show();
  IJ.run("Boats", "");
  id = IJ.getImage().getID();
  is = IJ.getImage().getStatistics();
  histo = is.histogram;
  print (is.mode);
  fhisto = new float[histo.length];
  fgamma = new float[histo.length];
  glut = new byte[256];

  fgamma = getGamma(min, max, 1);
  cp5 = new ControlP5(this);
  myChart = cp5.addChart("dataflow")
    .setPosition(50, 50)
    .setSize(256, 100)
    .setRange(0, histo[is.mode])
    .setView(Chart.AREA) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
    ;
  myGamma = cp5.addChart("gammaline")
    .setPosition(50, 50)
    .setSize(256, 100)
    .setRange(0, histo[is.mode])
    .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
    .setColorBackground(color(255, 10))  
    ;


  myChart.addDataSet("incoming");
  myGamma.addDataSet("gammacurve");
  myGamma.setColors("gammacurve", color(255));


  for (int i=0; i< histo.length; i++) fhisto[i]=histo[i];  
  myChart.setData("incoming", fhisto);
  myGamma.setData("gammacurve", fgamma);
  myGamma.setCaptionLabel("");


  range = cp5.addRange("rangeController")
    // disable broadcasting since setRange and setRangeValues will trigger an event
    .setBroadcast(false) 
    .setPosition(50, 50)
    .setSize(myChart.getWidth(), myChart.getHeight())
    .setHandleSize(10)
    .setRange(0, 255)
    .setRangeValues(min, max)
    .setLabelVisible(false)
    // after the initialization we turn broadcast back on again
    .setBroadcast(true)
    .setColorForeground(color(255, 40))
    .setColorBackground(color(255, 10))  
    .setColorActive(color(255, 255, 0, 100))  
    ;

  cp5.addSlider("gslider")
    .setPosition(myChart.getPosition()[0]+myChart.getWidth()+5, myChart.getPosition()[0])
    .setSize(10, myChart.getHeight())
    .setRange(0.001, 5) // values can range from big to small as well
    .setValue(1)
    .setSliderMode(Slider.FLEXIBLE)
    .setLabelVisible(false)
    ;

  cp5.addBang("gamma1")
    .setPosition(myChart.getPosition()[0]+myChart.getWidth()+5, myChart.getPosition()[0]+myChart.getHeight()+5)
    .setSize(10, 10)
    .setLabelVisible(false)     
    ;
}
public void gamma1() {
  cp5.getController("gslider").setValue(1);
}


void draw() {
  background(0);
}

void controlEvent(ControlEvent theControlEvent) {
  if (theControlEvent.isFrom("rangeController")) {
    min = int(theControlEvent.getController().getArrayValue(0));
    max = int(theControlEvent.getController().getArrayValue(1));
    fgamma = getGamma(min, max, cp5.getController("gslider").getValue());
  } else if (theControlEvent.isFrom("gslider")) {
    fgamma = getGamma(min, max, cp5.getController("gslider").getValue());
  }
  myGamma.setData("gammacurve", fgamma);
  updateImageLut();
}

float[] getGamma(int min, int max, float g) {
  for (int i = 0; i<histo.length; i++) {
    if (i<=min) {
      fgamma[i]=0;
      glut[i]=byte(0);
    } else if (i>=max) {
      fgamma[i]=histo[is.mode];
      glut[i]=byte(255);
    } else {
      fgamma[i] = pow(float((i-min))/float((max-min)), 1/g)  * histo[is.mode];
      glut[i] = byte (pow(float((i-min))/float((max-min)), 1/g)  * 255);
    }
  }
  return fgamma;
}

void updateImageLut() {
  ImagePlus imp = IJ.getImage();
  if (imp.getBitDepth()==24)
    IJ.error("Non-RGB image expected");
  ImageProcessor ip = imp.getProcessor();
  LUT lut = new LUT(glut, glut, glut);
  if (imp.isComposite())
    ((CompositeImage)imp).setChannelLut(lut);
  else
    ip.setColorModel(lut);
  imp.updateAndDraw();
}
