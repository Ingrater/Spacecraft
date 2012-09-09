module renderer.cvars;

struct CVars {
	double profile = 0; // 2 shows the recorded frames, 1 shows the profiler, 0 hides it
	double r_info = 1; // 0 = no renderer information is shown, 1 = fps and sps are shown, 2 = position and query box are printed additionaly
  double recordFrames = 0; // number of frames to record
}