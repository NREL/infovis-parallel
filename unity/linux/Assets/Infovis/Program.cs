using Google.Protobuf;
using Infovis.Protobuf;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using WebSocketSharp.Server;

using Debug = UnityEngine.Debug;


namespace Infovis {

  public class Program : MonoBehaviour {

    public string serviceHost = "0.0.0.0";

    public string servicePort = "8080";

    public string serviceName = "/InfoVis";

    public GameObject root;

    public InfoScreen infoScreen;

    public GameObject camera = null;

    public GameObject tool = null;

    public bool enableSelection = true;

    public bool enableTooltips = false;

    public bool useBoxes = true;

    private WebSocketServer server = null;

    private int frame = 0;

    void Start() {

      server = new WebSocketServer(BindingAddress());
      server.AddWebSocketService<GeometrySocket>(serviceName, () => new GeometrySocket(this) {IgnoreExtensions = true});
      Debug.Log("Starting service on" + BindingAddress() + serviceName);

      server.Start();

      Element.enableSelection = enableSelection;
      Element.enableTooltips = enableTooltips;
      Element.useBoxes = useBoxes;

      ShowService();

    }

    void Update() {

      while (pending.Count > 0)
        lock (pending)
          Handle(pending.Dequeue());

    }

    public void Display(string message, float duration) {
      infoScreen.ShowMessage(message, duration);
    }

    public void ShowService() {
      Display("Infovis Parallel\n" + BoundAddress() + serviceName, 5f);
    }

    public void Broadcast(Response response)
    {
      response.Shown = frame;
      server.WebSocketServices.Broadcast(response.ToByteArray());
    }

    private string BindingAddress() {
      return "ws://" + serviceHost + ":" + servicePort;
    }

    private string BoundAddress() {
      return "ws://" + Network.player.ipAddress + ":" + servicePort;
    }

    private Queue<Request> pending = new Queue<Request>();

    public void Process(Request request) {
      lock (pending)
        pending.Enqueue(request);
    }

    public void Refresh() {
    }

    private string NameFrame(int frame) {
      return "frame:" + frame;
    }

    private GameObject GetFrame(GameObject root, int frame) {

      if (frame == 0)
        return null;

      string name = NameFrame(frame);

      for (int i = 0; i < root.transform.childCount; ++i) {
        GameObject candidate = root.transform.GetChild(i).gameObject;
        if (candidate.name == name)
          return candidate;
       }

       GameObject frameObject = new GameObject();
       frameObject.SetActive(false);
       frameObject.name = name;
       frameObject.transform.parent = root.transform;

      return frameObject;
    }
        
    private void Handle(Request request) {

      if (request.Reset) {

        types.Clear();

        for (int i = 0; i < root.transform.childCount; ++i)
//        GameObject.Destroy(root.transform.GetChild(i).gameObject);
          GameObject.DestroyImmediate(root.transform.GetChild(i).gameObject);
        
        new WaitForSeconds(0.001f);

      }

      foreach (Geometry geometry in request.Upsert) {

        int frame = geometry.Fram;
        long identifier = geometry.Iden;
        short type = (short) geometry.Type;

        GameObject frameObject = GetFrame(root, frame);
        
        if (type != 0 && !types.ContainsKey(type))
          types[type] = new Dictionary<int, Dictionary<long, Element>>();

        foreach (Dictionary<int, Dictionary<long, Element>> frames in types.Where(entry => type == 0 || entry.Key == type).Select(entry => entry.Value)) {

          if (type != 0 && frame != 0 && !frames.ContainsKey(frame))
            frames[frame] = new Dictionary<long, Element>();
        
          foreach (Dictionary<long, Element> elements in frames.Where(entry => frame == 0 || entry.Key == frame).Select(entry => entry.Value)) {

            Element element = null;
            if (elements.TryGetValue(identifier, out element))
              elements[identifier] = Factory.UpdateElement(element, geometry);
            else if (frameObject != null)
              elements[identifier] = Factory.CreateElement(frameObject, geometry);

          }

        }

      }

      foreach (Dictionary<int, Dictionary<long, Element>> frames in types.Select(entry => entry.Value))
        foreach (Dictionary<long, Element> elements in frames.Select(entry => entry.Value))
          foreach (long identifier in request.Delete) {
            Element element = null;
            if (elements.TryGetValue(identifier, out element)) {
              elements.Remove(identifier);
              Factory.RemoveElement(element);
            }
          }

      if (request.Show != 0) {
        frame = request.Show;
        string name = NameFrame(request.Show);
        for (int i = 0; i < root.transform.childCount; ++i) {
          GameObject frameObject = root.transform.GetChild(i).gameObject;
          bool newActive = frameObject.name == name;
          if (frameObject.activeSelf != newActive)
            frameObject.SetActive(newActive);
        }
      }

      if (tool != null && request.Toolloc != null) {
        tool.transform.position = new Vector3((float) request.Toolloc.Posx, (float) request.Toolloc.Posy, (float) request.Toolloc.Posz);
        tool.transform.rotation = new Quaternion((float) request.Toolloc.Rotx, (float) request.Toolloc.Roty, (float) request.Toolloc.Rotz, (float) request.Toolloc.Rotw);
      }

      if (camera != null && request.Viewloc != null) {
        camera.transform.position = new Vector3((float) request.Viewloc.Posx, (float) request.Viewloc.Posy, (float) request.Viewloc.Posz);
        camera.transform.rotation = new Quaternion((float) request.Viewloc.Rotx, (float) request.Viewloc.Roty, (float) request.Viewloc.Rotz, (float) request.Viewloc.Rotw);
      }

    }

    private Dictionary<short, Dictionary<int, Dictionary<long, Element>>> types = new Dictionary<short, Dictionary<int, Dictionary<long, Element>>>();

  }

}
