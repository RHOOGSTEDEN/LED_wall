/*  Much of the serial data transfer code is modified from the
    OctoWS2811 movie2serial.pde - Transmit video data to 1 or more
      Teensy 3.0 boards running OctoWS2811 VideoDisplay.ino
    http://www.pjrc.com/teensy/td_libs_OctoWS2811.html
    Copyright (c) 2018 Paul Stoffregen, PJRC.COM, LLC
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/



import processing.video.*;
import processing.serial.*;
import java.awt.Rectangle;
import SimpleOpenNI.*;
import cc.arduino.*;
//import processing.sound.*;

// Declare the processing sound variables 
//AudioIn sample;
//Amplitude rms;
boolean audioOn  = true;   // start with audio reaction on?
boolean aBackOn  = true;  // start with audio background on?

int MAX_BRIGHTNESS = 255;  // starting brightness of the wall
float xoff = 0.0, yoff = 0.0, zoff = 0.0;              // used for perlin noise
// Declare a scaling factor
float scale = 7.50;

// Declare a smooth factor
float smoothFactor = 0.5;

// Used for smoothing
float sum;
float noiseInc = 0.2;
Arduino arduino;

//boolean switches for testing and protyping
boolean kinectOn = true;
boolean playMovie = false;
boolean LEDconnected = true;
boolean servoTrackOn = true;

boolean soundEffects = true;
int brightness = 128;

SimpleOpenNI  kinect;      
int [] userMap;
PImage transparent;  // a transparent image used to reset the user images  
final int KINECT_WIDTH  = 640;  // the x size of the kinect's depth image
final int KINECT_HEIGHT = 480;  // the y size of the kinect's depth image 

Movie myMovie;
float centerOfMassX=width/2;
float centerOfMassY=height/2;
//sweet spot for gamma correction
float gamma = 2.1;

///////////////////////////////////////////////////////////////////////////////////
//TODO: Edit this block out as there is only one Teensy needed for our LED display
///////////////////////////////////////////////////////////////////////////////////
int numPorts=0;  // the number of serial ports in use
int maxPorts=24; // maximum number of serial ports

Serial[] ledSerial = new Serial[maxPorts];     // each port's actual Serial port
Rectangle[] ledArea = new Rectangle[maxPorts]; // the area of the movie each port gets, in % (0-100)
boolean[] ledLayout = new boolean[maxPorts];   // layout of rows, true = even is left->right
PImage[] ledImage = new PImage[maxPorts];      // image sent to each port
//////////////////////////////////////////////////////////////////////////////////
int[] gammatable = new int[256];
int errorCount=0;
float framerate=0;


//Vectors used to calculate the center of the mass of a user
PVector com = new PVector();
PVector com2d = new PVector();
//servo starting position
int deg = 90;

ParticleSystem[] ps = new ParticleSystem[1];


// radius for balls
float radius=25;
ArrayList<Ball> balls = new ArrayList<Ball>();
int ballNumber = 10;

/////////////////////////////////////////////////////////////
// Background Modes
/////////////////////////////////////////////////////////////
int PARTICLE_SHOWER = 1;
int BALLS = 2;
int CHESS_GRID = 3;
int PULSAR = 4;
int SPIN = 5;
int PLAY_MOVIE = 6;
/////////////////////////////////////////////////////////////
int mode = 1;
void setup() {
  size(1200, 800, P3D); 
  setupMinim();
  setupPulsar();
  setupSpin();
  setupGrid();
  //The kinect has a framerate of 30 fps 
  //frameRate(30);
  delay(20);
  setupColors();
  //if(particleShower) {
    for (int i = 0; i<1; i++){
      ps[i] = new ParticleSystem(new PVector(width/2, -24));
    }
  //}
  
  //if (bouncingBalls) {
    for(int i = 0; i<ballNumber; i++) {
      balls.add( new Ball(random(radius,width-radius), random(radius, height-radius), radius));
    }
  //}
  
  if(kinectOn){
    transparent = createImage(KINECT_WIDTH, KINECT_HEIGHT, ARGB); // create the transparent image
    transparent.loadPixels();                                     // load it's pixels
    for (int i = 0; i < transparent.pixels.length; i++) {         // loop through the image pixels
      transparent.pixels[i] = color(0, 0, 0, 0);                  // and set them all to transparent
    }
    transparent.updatePixels();  
    
    if(servoTrackOn){
    arduino = new Arduino(this, "/dev/cu.usbmodem14501", 57600);
    arduino.pinMode(7, Arduino.SERVO);
    }
    kinect = new SimpleOpenNI(this);
    kinect.update();
    if(kinect.isInit() == false) {
         println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
         exit();
         return;  
    }
    kinect.enableDepth();
   
    // enable RGB camera
   // kinect.enableRGB(); 
   
    // enable skeleton generation for all joints
    kinect.enableUser();
   
    // turn on depth-color alignment 
   // kinect.alternativeViewPointDepthToImage();
    
    //TO-DO: find out why this function doesn't translate the image
   kinect.setMirror(true);
    
  }
  background(0);
  if (LEDconnected){
  serialConfigure("/dev/tty.usbmodem55473401");  
  }
  if (errorCount > 0) exit();
  
  //referencing a table is faster than constantly calculating the value
  for (int i=0; i < 256; i++) {
    gammatable[i] = (int)(pow((float)i / 255.0, gamma) * 255.0 + 0.5);
  }
  
  //if(playMovie) {
    //can be changed to any video in the data folder
    myMovie = new Movie(this, "lips.mp4");
    myMovie.loop();  // start the movie :-)
  //}
  
  //if(soundEffects){
  ////Load and play a soundfile and loop it
  //sample = new AudioIn(this, 0);
  //sample.start();

  //// Create and patch the rms tracker
  //rms = new Amplitude(this);
  //rms.input(sample);
  //}
}

void draw() {
  if (mousePressed == true) {
    if (mouseButton == LEFT) {
      mode -=1;
      mode = constrain(mode, 1, 6);
    } else if (mouseButton == RIGHT) { 
       mode +=1;
      mode = constrain(mode, 1, 6);
    }
  }
   updateNoise(); // update noise offsets
  colors.update();
  background(colors.background);
  colors.updateUsers();
 
  radius = 25 + radius *map(audio.volume.value, 0, 100, 0, 10);
  
  doMode(mode);
  loadPixels();
  PImage img = createImage(width, height, RGB);
  img.loadPixels();
  img.pixels = pixels;
  img.updatePixels();
  img.resize(640,480);
  if(kinectOn){
    //pull the latest data
    kinect.update();
    
    
    IntVector userList = new IntVector();
    if(servoTrackOn){
      //populate userList with all users being tracked
      kinect.getUsers(userList);
      if (userList.size() > 0) {
        int userId = userList.get(0);
        int i = 0;
        
        //check to see if any of the users have their skeletons being tracked, if so find center of mass
        while(i<userList.size()){
          userId = userList.get(i);
          if (kinect.isTrackingSkeleton(userId)) {     
            if (kinect.getCoM(userId,com)) {
              kinect.convertRealWorldToProjective(com,com2d);
              centerOfMassX = com2d.x;
              centerOfMassY = com2d.y;
              //println(centerOfMassX);
              // If the center of mass is not centered in the frame, rotate servo to pan kinect
              if(centerOfMassX < img.width/2 - 10) {
                deg += 1;
                deg = constrain(deg, 10, 170);
                arduino.servoWrite(7, deg);
                //delay(10);
              }
              if(centerOfMassX > img.width/2 + 10) {
                deg -= 1;
                deg = constrain(deg, 10, 170);
                arduino.servoWrite(7, deg);
                //delay(10);
              }
              //println(deg);
              
            }
          }
          i++;
        }     
      }
    }
    
    // get the Kinect depth image
    PImage depthImage = kinect.depthImage(); 
    
    // load the depth pixels in array
    depthImage.loadPixels();
    
    img.loadPixels();
   
    int[] userImageList = kinect.getUsers();
    if(userImageList.length > 0) {
      userMap = kinect.userMap();
      
     for(int i=0; i<userMap.length; i++)
      {
        if(userMap[i]!=0)
        {
         img.pixels[i] = color(colors.users[userMap[i]%12]);
     
           // set the sketch pixel to the color pixel
            //img.pixels[i] =depthImage.pixels[i];
        }
        //else
        //{
        //  img.pixels[i] = color(0);
        //}
      }
     img.updatePixels();
     
    } 
    
  }
  image(img,0,0,width, height);
  //img.loadPixels();
  //for (int i =img.width*img.height/2;i< img.width*img.height; i++){
  //  img.pixels[i] = reduceBrightness(img.pixels[i]);
  //}
  //img.updatePixels();
  img.resize(width,height);
  img.loadPixels();
  //loadPixels();
  //pixels = img.pixels;
  //updatePixels();
  
  //img.loadPixels();
  //loadPixels();
  //PImage img = createImage(width, height, RGB);
  //img.loadPixels();

    
  //img.pixels = img.pixels; 

  //img.updatePixels();
  if (LEDconnected){
  for (int i=0; i < numPorts; i++) {
    // copy a portion of the image to the LED image
    int xoffset = percentage(img.width, ledArea[i].x);
    int yoffset = percentage(img.height, ledArea[i].y);
    int xwidth =  percentage(img.width, ledArea[i].width);
    int yheight = percentage(img.height, ledArea[i].height);
    ledImage[i].copy(img, xoffset, yoffset, xwidth, yheight,
                     0, 0, ledImage[i].width, ledImage[i].height);
    // convert the LED image to raw data
    byte[] ledData =  new byte[(ledImage[i].width * ledImage[i].height * 3) + 3];
    image2data(ledImage[i], ledData, ledLayout[i]);
    if (i == 0) {
      ledData[0] = '*';  // first Teensy is the frame sync master
      int usec = (int)((1000000.0 / framerate) * 0.75);
      ledData[1] = (byte)(usec);   // request the frame sync pulse
      ledData[2] = (byte)(usec >> 8); // at 75% of the frame time
    } else {
      ledData[0] = '%';  // others sync to the master board
      ledData[1] = 0;
      ledData[2] = 0;
    }
    // send the raw data to the LEDs  :-)
    ledSerial[i].write(ledData);
  }
  }
}
void movieEvent(Movie m) {
  // read the movie's next frame
  framerate=30;
  m.read();
  ;
}
void doMode(int i){
  if(playMovie){
    
  }
  if(i ==PARTICLE_SHOWER){
    for(ParticleSystem system : ps){
    system.addParticle();
    system.run();
    }
  }
  if(i == BALLS){
    for (Ball b : balls) {
    b.update(radius);
    b.display();
    b.checkBoundaryCollision();
   
  }
   for(int j = 0; j <balls.size(); j++){
      for(Ball ball : balls){
        if(ball != balls.get(j)){
          balls.get(j).checkCollision(ball);
        }
      }
    }
  //balls[0].checkCollision(balls[1]);
  }
  if(i==PULSAR) pulsar.draw();
  if(i==SPIN) spin.draw();
  if(i==CHESS_GRID) grid.draw();
  if(i==PLAY_MOVIE) image(myMovie, 0, 0, width, height);;
}
// image2data converts an image to OctoWS2811's raw data format.
// The number of vertical pixels in the image must be a multiple
// of 8.  The data array must be the proper size for the image.
void image2data(PImage image, byte[] data, boolean layout) {
  int offset = 3;
  int x, y, xbegin, xend, xinc, mask;
  int linesPerPin = image.height / 8;
  int pixel[] = new int[8];

  for (y = 0; y < linesPerPin; y++) {
    if ((y & 1) == (layout ? 0 : 1)) {
      // even numbered rows are left to right
      xbegin = 0;
      xend = image.width;
      xinc = 1;
    } else {
      // odd numbered rows are right to left
      xbegin = image.width - 1;
      xend = -1;
      xinc = -1;
    }
    for (x = xbegin; x != xend; x += xinc) {
      for (int i=0; i < 8; i++) {
        // fetch 8 pixels from the image, 1 for each pin
        pixel[i] = image.pixels[x + (y + linesPerPin * i) * image.width];
        pixel[i] = colorWiring(pixel[i]);
      }
      // convert 8 pixels to 24 bytes
      for (mask = 0x800000; mask != 0; mask >>= 1) {
        byte b = 0;
        for (int i=0; i < 8; i++) {
          if ((pixel[i] & mask) != 0) b |= (1 << i);
        }
        data[offset++] = b;
      }
    }
  }
}

// translate the 24 bit color from RGB to the actual
// order used by the LED wiring.  GRB is the most common.
int colorWiring(int c) {
  int red = int(((c & 0xFF0000) >> 16));
  int green = int(((c & 0x00FF00) >> 8));
  int blue = int((c & 0x0000FF));
  red = (red * brightness) >> 8;
  green = ((green * brightness) >> 8);
  blue = (blue * brightness) >> 8;
  
  red = gammatable[int(red)];
  green = gammatable[green];
  blue = gammatable[blue];
  return (green << 16) | (red << 8) | (blue); // GRB - most common wiring
}

int dimColor(int c, int bright) {
  int b= bright;
  int red = int(((c & 0xFF0000) >> 16));
  int green = int(((c & 0x00FF00) >> 8));
  int blue = int((c & 0x0000FF));
  red = (red * b) >> 8;
  green = (green * b) >> 8;
  blue = (blue * b) >> 8;
  
  //red = gammatable[int(red)];
  //green = gammatable[green];
  //blue = gammatable[blue];
  return (red << 16) | (green << 8) | (blue);
}

// ask a Teensy board for its LED configuration, and set up the info for it.
void serialConfigure(String portName) {
  if (numPorts >= maxPorts) {
    println("too many serial ports, please increase maxPorts");
    errorCount++;
    return;
  }
  try {
    ledSerial[numPorts] = new Serial(this, portName);
    if (ledSerial[numPorts] == null) throw new NullPointerException();
    ledSerial[numPorts].write('?');
  } catch (Throwable e) {
    println("Serial port " + portName + " does not exist or is non-functional");
    errorCount++;
    return;
  }
  delay(50);
  String line = ledSerial[numPorts].readStringUntil(10);
  if (line == null) {
    println("Serial port " + portName + " is not responding.");
    println("Is it really a Teensy 3.0 running VideoDisplay?");
    errorCount++;
    return;
  }
  String param[] = line.split(",");
  if (param.length != 12) {
    println("Error: port " + portName + " did not respond to LED config query");
    errorCount++;
    return;
  }
  // only store the info and increase numPorts if Teensy responds properly
  ledImage[numPorts] = new PImage(Integer.parseInt(param[0]), Integer.parseInt(param[1]), RGB);
  ledArea[numPorts] = new Rectangle(Integer.parseInt(param[5]), Integer.parseInt(param[6]),
                     Integer.parseInt(param[7]), Integer.parseInt(param[8]));
  ledLayout[numPorts] = (Integer.parseInt(param[5]) == 0);
  numPorts++;
}






// scale a number by a percentage, from 0 to 100
int percentage(int num, int percent) {
  double mult = percentageFloat(percent);
  double output = num * mult;
  return (int)output;
}

// scale a number by the inverse of a percentage, from 0 to 100
int percentageInverse(int num, int percent) {
  double div = percentageFloat(percent);
  double output = num / div;
  return (int)output;
}

// convert an integer from 0 to 100 to a float percentage
// from 0.0 to 1.0.  Special cases for 1/3, 1/6, 1/7, etc
// are handled automatically to fix integer rounding.
double percentageFloat(int percent) {
  if (percent == 33) return 1.0 / 3.0;
  if (percent == 17) return 1.0 / 6.0;
  if (percent == 14) return 1.0 / 7.0;
  if (percent == 13) return 1.0 / 8.0;
  if (percent == 11) return 1.0 / 9.0;
  if (percent ==  9) return 1.0 / 11.0;
  if (percent ==  8) return 1.0 / 12.0;
  return (double)percent / 100.0;
}
void onNewUser(SimpleOpenNI kinect, int userID) {
        println("Start skeleton tracking");
        kinect.startTrackingSkeleton(userID);
}

void onLostUser(SimpleOpenNI curContext, int userId) {
        println("onLostUser - userId: " + userId);
}
void updateNoise() {
  xoff = xoff + noiseInc;
  if ( (frameCount % 2) == 0) yoff = yoff + 0.03;
  if ( (frameCount % 3) == 0) zoff = zoff + 0.02;
}
