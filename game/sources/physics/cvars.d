module physics.cvars;

struct CVars {
	double p_drawCollisionGeometry = 0.0; //if the collision geometry should be drawn or not
  double p_drawCollisionInfo = 0.0; //if collision information should be drawn or not
  double p_fixedTimestep = 0.0; //if > 0 used a timestep for physics simulation
  double p_gravity = 1.0; //if > 0 gravity is enabled
}