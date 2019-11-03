using Infovis.Protobuf;
using UnityEngine;


namespace Infovis {

  public static class Factory {

    public static Element CreateElement(GameObject root, Geometry geometry) {
      string identifier = geometry.Iden.ToString();
      Element result;
      switch (geometry.Type) {
        case 1:
          result = new Points(root, identifier);
          break;
        case 2:
          result = new Polylines(root, identifier);
          break;
        case 3:
          result = new Rectangles(root, identifier);
          break;
        case 4:
          result = new Label(root, identifier);
          break;
        case 5:
          result = new Axis(root, identifier);
          break;
        default:
          result = null;
          break;
      }
      result.Update(geometry);
      return result;

    }

    public static Element UpdateElement(Element element, Geometry geometry) {
      element.Update(geometry);
      return element;
    }

    public static void RemoveElement(Element element) {
      GameObject.Destroy(element.obj);
    }

  }

}
