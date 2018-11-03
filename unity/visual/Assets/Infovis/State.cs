using Infovis.Protobuf;
using System.Collections.Generic;
using UnityEngine;


namespace Infovis {

  public class State {

    public static void Process(Request request) {
      lock (pending)
        pending.Enqueue(request);
    }

    public static void Refresh() {
      while (pending.Count > 0)
        lock (pending) {
          Request request = pending.Dequeue();          
          state.Update(request);

        }
    }

    private State() {
    }

    private static Queue<Request> pending = new Queue<Request>();

    private static State state = new State();

    private void Update(Request request) {

      GameObject root = GameObject.Find("Root");

      if (request.Reset) {

        elements.Clear();

        foreach (GameObject obj in GameObject.FindGameObjectsWithTag("infovis"))
          GameObject.Destroy(obj);
//        GameObject.DestroyImmediate(obj);

        new WaitForSeconds(0.001f);

      }

      foreach (Geometry geometry in request.Upsert) {
        long identifier = geometry.Iden;
        Element element = null;
        if (elements.TryGetValue(identifier, out element))
          elements[identifier] = Factory.UpdateElement(element, geometry);
        else
          elements[identifier] = Factory.CreateElement(root, geometry);
      }

      foreach (long identifier in request.Delete) {
        Element element = null;
        if (elements.TryGetValue(identifier, out element)) {
          elements.Remove(identifier);
          Factory.RemoveElement(element);
        }
      }

    }

    private Dictionary<long, Element> elements = new Dictionary<long, Element>();

  }

}
