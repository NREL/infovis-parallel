using Google.Protobuf.Collections;
using Infovis.Protobuf;
using UnityEngine;


namespace Infovis {

  public class TangoSupport : MonoBehaviour {

    public Program program;

    public GameObject camera;

    public double deltaReport = 5;

    private double nextReport = 0;

    void Update() {

      if (Time.time >= nextReport) {
        GameObject tool = GameObject.Find("RightHandAnchor");
        Response response = new Response {
          Message = "Time: " + Time.time + "s",
          Viewloc = new Location {
            Posx = camera.transform.position.x,
            Posy = camera.transform.position.y,
            Posz = camera.transform.position.z,
            Rotw = camera.transform.rotation.w,
            Rotx = camera.transform.rotation.x,
            Roty = camera.transform.rotation.y,
            Rotz = camera.transform.rotation.z,
          },
        };
        program.Broadcast(response);
        nextReport = Time.time + deltaReport;
      }

    }

  }

}
