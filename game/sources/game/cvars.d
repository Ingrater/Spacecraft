module game.cvars;

struct CVars {
	double debugOctree = 0; // > 0 if octree should be debugged, <= 0 if not
	double debugObjects = 0; // > 0 if objects should be debugged, <= if not
  double p_doSteps = 0.0; //decremented until all steps are simulated
}