module physics.rigidbody;

import thBase.math3d.all;
import game.collision;

class RigidBody
{
  CollisionHull m_collision;
  float m_bouncieness;

  public:
    Position position;
    Quaternion rotation;
    vec3 velocity;

    @property float bounciness() const
    {
      return m_bouncieness;
    }

    @property const(CollisionHull) collision() const
    {
      return m_collision;
    }

    /**
     * Constructor
     * Params:
     *  collsion = the collision mesh to use
     */
    this(CollisionHull collision, float fBounciness)
    {
      m_collision = collision;
      m_bouncieness = fBounciness;
      rotation = Quaternion(vec3(1,0,0), 0);
      velocity = vec3(0,0,0);
    }

    /**
     * returns the transformation that will transform this
     * rigid body into the model space of another rigid body
     */
    mat4 transformTo(RigidBody other)
    {
      return other.rotation.toMat4().Inverse() * (TranslationMatrix(this.position - other.position) * this.rotation.toMat4());
    }
}