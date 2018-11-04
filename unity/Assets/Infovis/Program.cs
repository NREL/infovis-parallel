using Google.Protobuf;
using Infovis.Protobuf;
using UnityEngine;
using WebSocketSharp.Server;

using Debug = UnityEngine.Debug;
using Text = UnityEngine.UI.Text;


namespace Infovis {

  public class Program : MonoBehaviour {

    private const string serviceAddress = "ws://0.0.0.0:8080";

    private const string serviceName = "/InfoVis";

    private WebSocketServer server = null;

    public InfoScreen infoScreen;

    public bool enableSelection = true;

    public bool enableTooltips = false;

    public bool useBoxes = true;

    public double deltaReport = 5;

    private double nextReport = 0;

    void Start() {

      server = new WebSocketServer(serviceAddress);
      server.AddWebSocketService<GeometrySocket>(serviceName, () => new GeometrySocket() {IgnoreExtensions = true});
      Debug.Log("Starting service on " + serviceAddress + serviceName);

      server.Start();

      GameObject camera = GameObject.Find("OVRCameraRig");
      home = camera.transform.position;

      Element.enableSelection = enableSelection;
      Element.enableTooltips = enableTooltips;
      Element.useBoxes = useBoxes;

    }

    void Update() {

      State.Refresh();

      GameObject camera = GameObject.Find("OVRCameraRig");
      OVRInput.Controller controller = OVRInput.GetActiveController();

      if (OVRInput.GetDown(OVRInput.Button.Two, controller)) {

        camera.transform.position = home;

        infoScreen.ShowMessage("Infovis Parallel\nws://" + Network.player.ipAddress + ":8080", 5f);

      } else {

        Vector2 joystick = OVRInput.Get(OVRInput.Axis2D.PrimaryTouchpad, controller);
  
        if (OVRInput.GetDown(OVRInput.Button.One, controller))
          upwards = - upwards;
        float shift = OVRInput.Get(OVRInput.Button.One, controller) ? upwards : 0;
  
        camera.transform.position = camera.transform.position + 0.008f * (new Vector3(joystick[0], shift, joystick[1]));

      }

      if (OVRInput.GetDown(OVRInput.Button.PrimaryIndexTrigger, controller)) {
      }

      if (Time.time >= nextReport) {
        GameObject tool = GameObject.Find("RightHandAnchor");
        Response response = new Response {
          Message = "Time = " + Time.time + "s",
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
          }
        };
        Broadcast(response);
        nextReport = Time.time + deltaReport;
      }

    }

    public void Broadcast(Response response)
    {
      server.WebSocketServices.Broadcast(response.ToByteArray());
    }

    private Vector3 home = Vector3.zero;

    private float upwards = 0.5f;

  }

}
