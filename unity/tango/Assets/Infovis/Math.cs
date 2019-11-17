using UnityEngine;


namespace Infovis {

  public static class Math {

    // http://stackoverflow.com/questions/1171849/finding-quaternion-representing-the-rotation-from-one-vector-to-another

    private static float epsilon = 1e-6f;

    public static bool NearZero(Vector3 v) {
      return v.magnitude <= epsilon;
    }

    public static Quaternion MakeQuaternion(float s, Vector3 v) {
      return new Quaternion(v.x, v.y, v.z, s);
    }

    public static Quaternion RotationFromVectorPair(Vector3 v1, Vector3 v2) {
      Vector3 v1n = v1.normalized;
      Vector3 v2n = v2.normalized;
      Vector3 v12 = v1n + v2n;
      Vector3 v12n = v12.normalized;
      Quaternion q = MakeQuaternion(Vector3.Dot(v12n, v2n), Vector3.Cross(v12n, v2n));
      return NearZero(v12) ? MakeQuaternion(0, Orthogonal(v1n)) : q;
    }

    private static Vector3[] basis = {Vector3.right, Vector3.up, Vector3.forward};

    public static Vector3 Orthogonal(Vector3 v) {
      Vector3 w = Vector3.Cross(basis[0], v);
      if (!NearZero(w))
        return w.normalized;
      w = Vector3.Cross(basis[1], v);
      if (!NearZero(w))
        return w.normalized;
      w = Vector3.Cross(basis[2], v);
      return w.normalized;
    }

    public static Vector3 ProjectPlane(Vector3 v, Vector3 u) {
      Vector3 un = u.normalized;
      return v - Vector3.Dot(v, un) * un;
    }

    public static Quaternion RotationFromVectorPairs(Vector3 u0, Vector3 v0, Vector3 u2, Vector3 v2) {
      Quaternion q2 = RotationFromVectorPair(u0, u2);
      Vector3 v1 = Quaternion.Inverse(q2) * v2;
      Vector3 v0p = ProjectPlane(v0, u0).normalized;
      Vector3 v1p = ProjectPlane(v1, u0).normalized;
      Quaternion q1 = NearZero(v0p + v1p) ? MakeQuaternion(0, u0.normalized) : RotationFromVectorPair(v0p, v1p);
      return (q2 * q1)/*.normalized*/;
    }


    public static Quaternion RotationFromPlane(Vector3 xAxis, Vector3 yAxis, Vector3 origin, Vector3 xPoint, Vector3 yPoint) {
      return RotationFromVectorPairs(xAxis, yAxis, xPoint - origin, yPoint - origin);
    }

  }

}
