Pulsar pulsar;

void setupPulsar() {
  pulsar = new Pulsar();
}

class Pulsar {
  color lineColor;
  float kx, ky;
  float Z = -5;
  PVector kinectUser = new PVector(width/2, height/2);
  PVector velocity;
  
  int maxSpecs;

  Pulsar() {
    maxSpecs = audio.fullSpecs.length;
    velocity = PVector.random2D();
    velocity.mult(5);
   // 2;
  }

  color setColor(int i) {
    int r = 0, g = 0, b = 0;
    /*
    int s = round(random(3));
    switch(s) {
      case 0:
        r = audio.averageSpecs[1].grey;
        g = audio.averageSpecs[3].grey;
        b = audio.fullSpecs[i].grey;
        break;
      
      case 1:
        b = audio.averageSpecs[1].grey;
        r = audio.averageSpecs[3].grey;
        g = audio.fullSpecs[i].grey;
        break;
      
      case 2:
        g = audio.averageSpecs[1].grey;
        b = audio.averageSpecs[3].grey;
        r = audio.fullSpecs[i].grey;
        break;
    }
    */
    r = audio.averageSpecs[1].grey;
    g = audio.averageSpecs[3].grey;
    b = audio.fullSpecs[i].grey;
    color c = color(r,g,b);
    return c;
  }

  void drawLine(float radius, float angle) {
    float x = kinectUser.x + ( radius * cos( radians(angle) ) );
    float y = kinectUser.y + ( radius * sin( radians(angle) ) );
    
    //buffer.pushMatrix();
    //buffer.rectMode(RADIUS);
    //buffer.translate(kinectUser.x, kinectUser.y, 0);
    //buffer.rect(80,40,x,y);
    
    if (kinectUser.x == 80 && kinectUser.y == 40)
      line(kinectUser.x, kinectUser.y, Z, x, y, 0);
    else
      line(kinectUser.x, kinectUser.y, Z, x, y, Z);
    //buffer.popMatrix();

  }

  void draw() {
    checkBoundaryCollision(); 
   // kinectUser.add(velocity.mult(map(audio.volume.value, 0, 100, 1, 5)));
    kinectUser.add(velocity);
    kinectUser.x+=(map(audio.volume.value, 0, 100, 0, 2));
    kinectUser.y+=(map(audio.volume.value, 0, 100, 0, 2));
    pushStyle();
   // rotateX(PI/8);
    blendMode(ADD);
    //buffer.blendMode(REPLACE);
    //doBackground();
    
    noFill();
   // kinectUser = getSingleUser();

    for (int i = 0; i < maxSpecs; i++) {    
      //buffer.strokeWeight(1);
      //buffer.stroke(0);
      stroke( setColor(i) );
      //fill(setColor(i));
      int weight = round(map(audio.fullSpecs[i].value, 0, 100, 1, 160));
      strokeWeight(weight);

      float angle  = map(i, 0, (audio.fullSpecs.length - 1) / 4, 0, 180);
      float radius = map(audio.fullSpecs[i].value, 0, 100, 1, 5000);
      float spin   = map(audio.volume.value, 0, 100, 0, 180);

      drawLine(radius, angle + spin);
      drawLine(radius, angle + 180 + spin);
    }
    blendMode(BLEND);
    popStyle();
  }
    void checkBoundaryCollision() {
    if (kinectUser.x > width) {
      kinectUser.x = width;
      velocity.x *= -1;
    } else if (kinectUser.x < 0) {
      kinectUser.x = 0;
      velocity.x *= -1;
    } else if (kinectUser.y > height) {
      kinectUser.y = height;
      velocity.y *= -1;
    } else if (kinectUser.y < 0) {
      kinectUser.y = 0;
      velocity.y *= -1;
    }
  }
}
