// Copyright (C) 2020 RunwayML Examples
// 
// This file is part of RunwayML Examples.
// 
// Runway-Examples is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// Runway-Examples is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with RunwayML.  If not, see <http://www.gnu.org/licenses/>.
// 
// ===========================================================================

// RUNWAYML
// www.runwayml.com

// DenseDepth
// Receive HTTP messages from Runway
// Running DenseDepth model
// example by George Profenza

// import video library
import processing.video.*;

// import Runway library
import com.runwayml.*;
// reference to runway instance
RunwayHTTP runway;

PImage runwayResult;

// periocally to be updated using millis()
int lastMillis;
// how often should the above be updated and a time action take place ?
int waitTime = 1000;

// reference to the camera
Capture camera;

// status
String status = "waiting ~"+(waitTime/1000)+"s";

void setup() {
  // match sketch size to default model camera setup
  size(1280, 480);
  // setup Runway
  runway = new RunwayHTTP(this);
  // update manually
  runway.setAutoUpdate(false);
  // setup camera
  camera = new Capture(this, 640, 480);
  camera.start();
  // setup timer
  lastMillis = millis();
}

//PImage threshhold = new PImage(0,0,600,400);
PImage thresholdImage = createImage(640, 480, ARGB);
int threshold = 103;

void draw() {
  background(255, 0, 0);
  // update timer
  int currentMillis = millis();
  // if the difference between current millis and last time we checked past the wait time
  if (currentMillis - lastMillis >= waitTime) {
    status = "sending image to Runway";
    // call the timed function
    sendFrameToRunway();
    // update lastMillis, preparing for another wait
    lastMillis = currentMillis;
  }

  // draw image received from Runway
  if (runwayResult != null) {
    camera.loadPixels();
    runwayResult.loadPixels();
    thresholdImage.loadPixels();
    for (int a= 0; a<runwayResult.pixels.length; a++) {
      thresholdImage.pixels[a] = camera.pixels[a];
      if (red(runwayResult.pixels[a]) > threshold) {
        thresholdImage.pixels[a] = color(255, 255, 255, 0);
      } else {
        thresholdImage.pixels[a] = camera.pixels[a];
        //thresholdImage.pixels[a] = color(random(100,255),random(100,255),random(100,255));

        // (x,y) index = y * img.height + x 
        // clr : img.pixels[index]
      }
    } 
    image(camera, 640, 0);
    for (int x=0; x <thresholdImage.width; x += 6) {
      for (int y=0; y < thresholdImage.height; y += 6) {
        int index = y*thresholdImage.width+x; 

        noStroke();
        fill(thresholdImage.pixels[index]);
        rect(640+x, y, 6, 6);
      }
    }


    runwayResult.updatePixels();
    camera.updatePixels();
    thresholdImage.updatePixels();
    //image(camera, 640, 0);

    //for (int x=0; x <thresholdImage.width; x += 10) {
    //  for (int y=0; y < thresholdImage.height; y += 10) {
    //    int index = y*thresholdImage.width+x; 

    //    noStroke();
    //    fill(thresholdImage.pixels[index]);
    //    rect(640+x, y, 10, 10);
    //  }
    //}

  }




  // draw camera feed
  image(camera, 0, 0, 640, 480);

  // display status
  text(status, 5, 15);
}
void sendFrameToRunway() {
  // nothing to send if there's no new camera data available
  if (camera.available() == false) {
    return;
  }
  // read a new frame
  camera.read();
  // crop image to Runway input format (600x400)
  PImage image = camera.get(0, 0, 640, 480);
  // query Runway
  runway.query(image);
}


// this is called when new Runway data is available
void runwayDataEvent(JSONObject runwayData) {
  // point the sketch data to the Runway incoming data 
  String base64ImageString = runwayData.getString("depth_image");
  // try to decode the image from
  try {
    runwayResult = ModelUtils.fromBase64(base64ImageString);
  }
  catch(Exception e) {
    e.printStackTrace();
  }
  status = "received runway result";
}

// this is called each time Processing connects to Runway
// Runway sends information about the current model
public void runwayInfoEvent(JSONObject info) {
  println(info);
}
// if anything goes wrong
public void runwayErrorEvent(String message) {
  println(message);
}

public void runwayData(JSONObject runwayData) {
  println(runwayData);
}
