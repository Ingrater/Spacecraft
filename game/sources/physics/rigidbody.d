module physics.rigidbody;

import base.physics;
import thBase.math3d.all;
import game.collision;

class RigidBody : IRigidBody
{
  CollisionHull m_collision;
  float m_inverseMass;

  public:
    float remainingTime;
    float inverseResolveMass;

    @property float inverseMass() const
    {
      return m_inverseMass;
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
    this(CollisionHull collision, float fInverseMass)
    {
      m_collision = collision;
      m_inverseMass = fInverseMass;
      inverseResolveMass = fInverseMass;
      rotation = Quaternion(vec3(1,0,0), 0);
      velocity = vec3(0,0,0);
    }

    /**
     * returns the transformation that will transform this
     * rigid body into the model space of another rigid body
     */
    mat4 transformTo(RigidBody other)
    {
      return this.rotation.toMat4() * TranslationMatrix(this.position - other.position) * other.rotation.toMat4().Transpose();
    }
}