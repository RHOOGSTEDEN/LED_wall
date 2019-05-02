// A simple Particle class

class Particle_dot {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float lifespan;
  float r = 255;
  float g = 255; 
  float b = 255;
  Particle_dot(PVector l) {
    acceleration = new PVector(0, 0.05);
    velocity = new PVector(random(-10,10), random(-2, 0));
    position = l.copy();
    lifespan = 255.0;
  }

  void run() {
    update();
    display();
  }

  // Method to update position
  void update() {
    velocity.add(acceleration);
    position.add(velocity);
    lifespan -= 1.2;
    g -= 1.0;
    
  }

  // Method to display
  void display() {
    stroke(255, lifespan);
    fill(r, g, b, lifespan);
    ellipse(position.x, position.y, 16, 16);
  }

  // Is the particle still useful?
  boolean isDead() {
    if (lifespan < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}
