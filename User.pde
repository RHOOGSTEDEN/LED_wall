class User {
  float x = 0.0;
  float y = 0.0;
  float z = 0.0;
  PVector realWorld;
  PVector projWorld;
  PVector headJoint;
  int id;
  //boolean active;
  boolean skeleton;
  boolean isSet;
  PImage img, userImage;
  int[] depthMap;
  int depthMAX, depthMIN;
  int colorIndex;
  color c;

  User(int i) {
    id = i;
    setup();
  }

  void setup() {
    userImage = createImage(KINECT_WIDTH, KINECT_HEIGHT, ARGB);
    userImage.loadPixels();
    arrayCopy(transparent.pixels, userImage.pixels);
    userImage.updatePixels();
    img = createImage(60, 40, ARGB);
    img.loadPixels();
    colorIndex = id % 12;
    depthMap = new int [userImage.pixels.length];
    depthMAX = 0;
    depthMIN = 9000;
    realWorld = new PVector();
    projWorld = new PVector();
    headJoint = new PVector();
  }

  void resetPixels() {
    arrayCopy(transparent.pixels, userImage.pixels);
    userImage.updatePixels();
    depthMAX = 0;
    depthMIN = 9000;
  }

  void setPixel(int index, int depth) {
    if (index > 0 && index < userImage.pixels.length) {
      userImage.pixels[index] = c;
      depthMap[index] = depth;
      depthMAX = max(depth, depthMAX);
      depthMIN = min(depth, depthMIN);
    }
  }

  void copyImage() {
    userImage.updatePixels();
    img.copy(userImage, 0, 0, KINECT_WIDTH, KINECT_HEIGHT, 0, 0, 60, 40);
  }

  void updatePixels(boolean mapDepth) {
    if (mapDepth) {
      //MAP_TIME = 0;
      //int stime = millis();

      int tr = (c >> 16) & 0xFF;  // get the red value of the user's color
      int tg = (c >> 8) & 0xFF;   // get the green value of the user's color
      int tb =  c & 0xFF;         // get the blue value of the user's color

      for (int i = 0; i < userImage.pixels.length; i++) {
        if (userImage.pixels[i] == 0) continue;
        float r = map(depthMap[i], depthMAX, depthMIN, 16, tr);  // map brightness from depth image to the red of the user color
        float g = map(depthMap[i], depthMAX, depthMIN, 16, tg);  // map brightness from depth image to the green of the user color
        float b = map(depthMap[i], depthMAX, depthMIN, 16, tb);  // map brightness from depth image to the blue of the user color
        userImage.pixels[i] = color(r, g, b);
      }
      //MAP_TIME = millis() - stime;
      //MAX_MAP = max(MAX_MAP, MAP_TIME);
    }
    copyImage();
  }

  boolean onScreen() {
    return isSet;
  }



  boolean hasSkeleton() {
    return skeleton;
  }

  void setSkeleton(boolean a) {
    skeleton = a;
  }

  void setIndex(int i) {
    id = i;
  }

  int index() {
    return id;
  }

  //void setColor() {
  //  c = audio.colors.users[colorIndex];
  //}

  void updateCoM(PVector projected) {
    // set the user location based on the wall size
    x = projected.x / 4;  // div by 4 because the wall is 4 times 
    y = projected.y / 4;  // smaller then the kinect user image
    z = (projected.z / 500) * -1;    // bring things closer.  May want to remove this

    //z = (525 / z);

    // check make sure we have real numbers
    if ( x != x || y != y || z != z) {    // checking for NaN
      isSet = false;  // got NaN so we're not set
    } 
    else { // all is good
      resetPixels();
      c = colors.users[colorIndex];
      isSet = true;
    }
  }

  void update() {
    //println("getting CoM for user: " + id);
    if ( kinect.getCoM(id, realWorld) ) {        // try to set center of mass real world location
      // let's try to get the head joint, which is better then the CoM
      //println("got CoM");

      float confidence = kinect.getJointPositionSkeleton(id, SimpleOpenNI.SKEL_HEAD, headJoint);
      if (confidence < 0.5) {
        // not very good, so lets use the CoM
        skeleton = false; // bad skeleton, bad!
        kinect.convertRealWorldToProjective(realWorld, projWorld);  // convert real world to projected world
        updateCoM(projWorld);
      } 
      else { 
        skeleton = true; // good skeley, good boy!
        kinect.convertRealWorldToProjective(headJoint, projWorld);  // convert real world to projected world
        updateCoM(projWorld);
      }
    } 
    else {
      isSet = false;    // couldn't get CoM so nothing is set.
    }
  }
}
