using Infovis.Protobuf;
using System.Collections.Generic;
using System.Linq;
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
        
    private void Update(Request request) {

      GameObject root = GameObject.Find("Program");

      if (request.Reset) {

        types.Clear();

        for (int i = 0; i < root.transform.childCount; ++i)
          GameObject.Destroy(root.transform.GetChild(i).gameObject);
//        GameObject.DestroyImmediate(obj);
        
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
        string name = NameFrame(request.Show);
        for (int i = 0; i < root.transform.childCount; ++i) {
          GameObject frameObject = root.transform.GetChild(i).gameObject;
          bool newActive = frameObject.name == name;
          if (frameObject.activeSelf != newActive)
            frameObject.SetActive(newActive);
        }
      }

    }

    private Dictionary<short, Dictionary<int, Dictionary<long, Element>>> types = new Dictionary<short, Dictionary<int, Dictionary<long, Element>>>();

  }

}
