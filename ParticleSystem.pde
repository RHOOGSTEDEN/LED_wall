// A class to describe a group of Particles
// An ArrayList is used to manage the list of Particles 

class ParticleSystem {
  ArrayList<Particle_dot> particles;
  PVector origin;

  ParticleSystem(PVector position) {
    origin = position.copy();
    particles = new ArrayList<Particle_dot>();
  }

  void addParticle() {
    particles.add(new Particle_dot(origin));
  }

  void run() {
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle_dot p = particles.get(i);
      p.run();
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }
}
