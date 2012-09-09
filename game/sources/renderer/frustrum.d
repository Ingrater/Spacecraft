module renderer.frustrum;

import thBase.math3d.all;

struct Frustrum {
private:
	Plane[6] m_Planes;
public:
	/**
	 * constructor
	 * Params:
	 *  Clip = clipping matrix to construct the frustrum from
	 */
	this(mat4 Clip){
	  m_Planes[0] = Plane( Clip.f[ 3] - Clip.f[ 0],
						   Clip.f[ 7] - Clip.f[ 4],
						   Clip.f[11] - Clip.f[ 8],
						   Clip.f[15] - Clip.f[12] );

	  m_Planes[1] = Plane( Clip.f[ 3] + Clip.f[ 0],
						   Clip.f[ 7] + Clip.f[ 4],
						   Clip.f[11] + Clip.f[ 8],
						   Clip.f[15] + Clip.f[12] );

	  m_Planes[2] = Plane( Clip.f[ 3] + Clip.f[ 1],
						   Clip.f[ 7] + Clip.f[ 5],
						   Clip.f[11] + Clip.f[ 9],
						   Clip.f[15] + Clip.f[13] );

	  m_Planes[3] = Plane( Clip.f[ 3] - Clip.f[ 1],
						   Clip.f[ 7] - Clip.f[ 5],
						   Clip.f[11] - Clip.f[ 9],
						   Clip.f[15] - Clip.f[13] );

	  m_Planes[4] = Plane( Clip.f[ 3] - Clip.f[ 2],
						   Clip.f[ 7] - Clip.f[ 6],
						   Clip.f[11] - Clip.f[10],
						   Clip.f[15] - Clip.f[14] );

	  m_Planes[5] = Plane( Clip.f[ 3] + Clip.f[ 2],
						   Clip.f[ 7] + Clip.f[ 6],
						   Clip.f[11] + Clip.f[10],
						   Clip.f[15] + Clip.f[14] );

	  //Normalize Planes
	  for(int i=0;i<6;i++)
		m_Planes[i] = m_Planes[i].normalize();
	}

	/**
     * Returns: all 8 corners of the frustrum
     */
	vec3[8] corners(){		
		vec3[8] points;
		points[0] = m_Planes[0].intersect(m_Planes[2],m_Planes[4]);
		points[1] = m_Planes[0].intersect(m_Planes[3],m_Planes[4]);
		points[2] = m_Planes[1].intersect(m_Planes[2],m_Planes[4]);
		points[3] = m_Planes[1].intersect(m_Planes[3],m_Planes[4]);
		points[4] = m_Planes[0].intersect(m_Planes[2],m_Planes[5]);
		points[5] = m_Planes[0].intersect(m_Planes[3],m_Planes[5]);
		points[6] = m_Planes[1].intersect(m_Planes[2],m_Planes[5]);
		points[7] = m_Planes[1].intersect(m_Planes[3],m_Planes[5]);
		
		return points;
	}
}