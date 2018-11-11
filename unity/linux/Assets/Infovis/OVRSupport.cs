using Google.Protobuf.Collections;
using Infovis.Protobuf;
using UnityEngine;


namespace Infovis {

  public class OVRSupport : MonoBehaviour {

    public Program program;

    public GameObject camera;

    public double deltaReport = 5;

    private double nextReport = 0;

    private Vector3 home = Vector3.zero;

    private float upwards = 0.5f;

    void Start() {

      home = camera.transform.position;

      program.ShowService();

    }

    void Update() {

      if (OVRInput.GetDown(OVRInput.Button.Two)) {

        camera.transform.position = home;

      } else {

        Vector2 joystick = OVRInput.Get(OVRInput.Axis2D.PrimaryTouchpad);
  
        if (OVRInput.GetDown(OVRInput.Button.One))
          upwards = - upwards;
        float shift = OVRInput.Get(OVRInput.Button.One) ? upwards : 0;
  
        camera.transform.position = camera.transform.position + 0.008f * (new Vector3(joystick[0], shift, joystick[1]));

      }

      uint depressed = 0;
      uint pressed = 0;
      uint released = 0;
      for (int i = 0; i < 32; ++i) {
        uint mask = 1U << i;
        OVRInput.Button button = (OVRInput.Button) mask;
        if (OVRInput.Get(button))
          depressed |= mask;
        if (OVRInput.GetDown(button))
          pressed |= mask;
        if (OVRInput.GetUp(button))
          released |= mask;
      }

      double[] analog = new double[12];
      for (int i = 0; i < 4; ++i) {
        uint mask = 1U << i;
        analog[i]  = OVRInput.Get((OVRInput.Axis1D) mask);
        Vector2 xy = OVRInput.Get((OVRInput.Axis2D) mask);
        analog[2 * i + 4] = xy.x;
        analog[2 * i + 5] = xy.y;
      }

      if (pressed != 0 || released != 0 || Time.time >= nextReport) {
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
          Toolloc = new Location {
            Posx = tool.transform.position.x,
            Posy = tool.transform.position.y,
            Posz = tool.transform.position.z,
            Rotw = tool.transform.rotation.w,
            Rotx = tool.transform.rotation.x,
            Roty = tool.transform.rotation.y,
            Rotz = tool.transform.rotation.z,
          },
          Depressed = depressed,
          Pressed   = pressed  ,
          Released  = released ,
        };
        response.Analog.Add(analog);
        program.Broadcast(response);
        nextReport = Time.time + deltaReport;
      }

    }

  }

}
