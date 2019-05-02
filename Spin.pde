
ConcCircles spin;

void setupSpin() {
  spin = new ConcCircles();
 
  
}








class ConcCircles {
  float r = 16;
  float theta = 0;
  float numCircles = 38;
  int rows = 8;
  PVector kinectUser;
  int maxSize;
  int size;
  float grow;
  float gAmount = 0.35;

  ConcCircles() {
    maxSize = 16;
    kinectUser = new PVector();
  }

  color getCircleColor(int i) {
    int m = i % (audio.averageSpecs.length - 1);
    color c = getBright(colors.colorMap(1,3,m));
    //color c = colors.colorMap(1,3,m);
    return c;
  }
  
  int getCirlceSize(int i) {
    if (audioOn) {
      int m = i % (audio.averageSpecs.length - 1);
      return round( map(audio.averageSpecs[m].value + 10, 10, 110, 2, maxSize) );
    } else {
      return round( random(2, maxSize) );
    }
  }

  void updateTheta() {
    int speed;
    
    // is the audio on?
    if (audioOn) speed = audio.BPM + 1;
    else speed = round( random(50,200) );
    
    // update theta
    if (theta > 0) theta += 360 / numCircles / speed;
    else theta -= 360 / numCircles / speed;
  }

  void drawCircle(int n, int size) {
    //float r2 = r + random(3);
    float x = (r+16*n)*cos(theta) + width/2;
    float y = (r+16*n)*sin(theta) + height/2;
    float z = -5;
    pushMatrix();
    translate(x, y);
    ellipse(0, 0, size + grow, size + grow);
    //sphere(size);
    popMatrix();
    grow += gAmount;
  }
  
  void update() {
    grow = 0;
    if ( audioOn ) {
      if ( audio.isOnBeat() ) {
        float test = random(0, 1);
        if (test < 0.25) theta = random(theta * -1, theta);
        if (test > 0.75) theta *= -1;
      }
    } else {
      float test = random(0, 1);
      if (test < 0.1) theta = random(theta * -1, theta);
      if (test > 0.9) theta *= -1;
    }
  }

  void draw() {
    update();
    blendMode(ADD);
    //buffer.blendMode(REPLACE);
    doBackground();
   // kinectUser = getSingleUser();
    
    //buffer.stroke(0);
    //buffer.strokeWeight(0.5);
    noStroke();

    for (int i = 0; i < rows ; i++) {
      fill( getCircleColor(i) );
      size = getCirlceSize(i);
      for (int n = 0; n < numCircles; n++) {
        drawCircle(n, size);
        updateTheta();
      }
    }

    blendMode(BLEND);
  }
}
