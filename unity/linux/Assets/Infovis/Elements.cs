using Infovis.Protobuf;
using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;

using Convert = System.Convert;
using Debug = UnityEngine.Debug;
using Float = System.Single;


namespace Infovis {

  public abstract class Element {

    public static bool enableSelection = true;

    public static bool enableTooltips = false;

    public GameObject obj = null;

    public float size = 0;

    public Color color = Color.white;

    public string text = "";

    public bool useBoxes = true;

    public bool selected = false;

    public bool inside = false;

    protected static GameObject MakeGeometric() {
      GameObject obj = new GameObject();
      obj.AddComponent<MeshRenderer>();
      return obj;
    }

    public Element(GameObject root, GameObject o, string identifier) {
      obj = o;
      obj.name = identifier;
      obj.tag = "infovis";
      obj.transform.parent = root.transform;
      AddTrigger(obj);
    }

    public virtual void Update(Geometry geometry) {
      PreUpdate(geometry);
      PostUpdate(geometry);
    }

    protected void AddTrigger(GameObject child) {

      if (enableSelection) {

        EventTrigger trigger = child.AddComponent<EventTrigger>();

        EventTrigger.Entry entry = new EventTrigger.Entry();
        entry.eventID = EventTriggerType.PointerClick;
        entry.callback.AddListener(data => { OnPointerClickDelegate((PointerEventData) data); });
        trigger.triggers.Add(entry);

      }

      if (enableTooltips) {

        EventTrigger trigger = child.AddComponent<EventTrigger>();

        EventTrigger.Entry entry = new EventTrigger.Entry();
        entry.eventID = EventTriggerType.PointerEnter;
        entry.callback.AddListener(data => { OnPointerEnterDelegate((PointerEventData) data); });
        trigger.triggers.Add(entry);
    
        entry = new EventTrigger.Entry();
        entry.eventID = EventTriggerType.PointerExit;
        entry.callback.AddListener(data => { OnPointerExitDelegate((PointerEventData) data); });
        trigger.triggers.Add(entry);

      }

    }

    private Program program = null;

    private void Display(string message, float duration) {
      if (program == null)
        program = GameObject.Find("Program").GetComponent<Program>();  
      program.Display(message, duration);
    }

    private void Broadcast(Response response) {
      if (program == null)
        program = GameObject.Find("Program").GetComponent<Program>();  
      program.Broadcast(response);
    }

    public void OnPointerClickDelegate(PointerEventData data) {
      selected = !selected;
      Response response =
        selected
          ? new Response {
              Message = "Selected " + obj.name + ": " + text,
              Select = {Convert.ToInt64(obj.name)}
            }
          : new Response {
              Deselect = {Convert.ToInt64(obj.name)}
            };
      Broadcast(response);
    }

    public void OnPointerEnterDelegate(PointerEventData data) {
      if (inside)
        return;
      inside = true;
      if (text != "")
        Display(text, 1f); //Float.PositiveInfinity);
      Response response = new Response {
        Hover = {Convert.ToInt64(obj.name)}
      };
      Broadcast(response);
    }

    public void OnPointerExitDelegate(PointerEventData data) {
      if (!inside)
        return;
      inside = false;
//    if (text != "")
//      Display("", -1f);
      Response response = new Response {
        Unhover = {Convert.ToInt64(obj.name)}
      };
      Broadcast(response);
    }

    protected void PreUpdate(Geometry geometry) {

      if (DirtyGlyph(geometry))
        useBoxes = geometry.Glyp == 0;

      if (DirtySize(geometry)) {
        Debug.Assert(geometry.Size >= 0, "Size must be non-negative: " + obj.name);
        size = (float) geometry.Size;
      }

      if (DirtyColor(geometry)) {
        float r = (geometry.Colr & 0xFF000000) / (float) 0xFF000000;
        float g = (geometry.Colr & 0x00FF0000) / (float) 0x00FF0000;
        float b = (geometry.Colr & 0x0000FF00) / (float) 0x0000FF00;
        float a = (geometry.Colr & 0x000000FF) / (float) 0x000000FF;
        color = new Color(r, g, b, a);
      }

      if (DirtyText(geometry))
        text = geometry.Text;

    }

    private static Material transparentMaterial = null;

    protected void PostUpdate(Geometry geometry) {

      if (DirtyColor(geometry)) {
        if (transparentMaterial == null)
          transparentMaterial = Resources.Load<Material>("transparent-material");
        obj.GetComponent<Renderer>().material.color = color;
        foreach (MeshRenderer renderer in obj.GetComponentsInChildren<MeshRenderer>()) {
          if (renderer.material.name != "font-material (Instance)")
            renderer.material = transparentMaterial;
          renderer.material.color = color;
        }
      }

    }

    protected void DestroyChildren() {
       foreach (Transform child in obj.transform) {
         child.parent = null;
         GameObject.Destroy(child.gameObject);
       }
    }

    protected static bool DirtyLocation(Geometry geometry) {
      return (geometry.Mask & 1 << 0) != 0;
    }

    protected static bool DirtySize(Geometry geometry) {
      return (geometry.Mask & 1 << 1) != 0;
    }

    protected static bool DirtyColor(Geometry geometry) {
      return (geometry.Mask & 1 << 2) != 0;
    }

    protected static bool DirtyText(Geometry geometry) {
      return (geometry.Mask & 1 << 3) != 0;
    }

    protected static bool DirtyGlyph(Geometry geometry) {
      return (geometry.Mask & 1 << 4) != 0;
    }

  }

  public class Points : Element {

    public Points(GameObject root, string identifier)
      : base(root, MakeGeometric(), identifier) {
    }

    public override void Update(Geometry geometry) {

      base.PreUpdate(geometry);

      if (DirtyLocation(geometry)) {

        DestroyChildren();

        int n = geometry.Cnts.Sum();
        Debug.Assert(geometry.Posx.Count == n, "Number of x positions must match count: " + obj.name);
        Debug.Assert(geometry.Posy.Count == n, "Number of y positions must match count: " + obj.name);
        Debug.Assert(geometry.Posz.Count == n, "Number of z positions must match count: " + obj.name);

        for (int i = 0; i < n; ++i) {
          GameObject point = GameObject.CreatePrimitive(useBoxes ? PrimitiveType.Cube : PrimitiveType.Sphere);
//        AddTrigger(point); // FIXME: Why isn't this necessary?
          point.transform.parent = obj.transform;
          point.transform.localPosition = new Vector3((float) geometry.Posx[i], (float) geometry.Posy[i], (float) geometry.Posz[i]);
        }

      }

      if (DirtyLocation(geometry) || DirtySize(geometry)) {
        float radius = size / 2;
        Vector3 scale = new Vector3(radius, radius, radius);
        foreach (Transform point in obj.transform)
          point.localScale = scale;
      }

      base.PostUpdate(geometry);

    }

  }
    
  public class Polylines : Element {

    public Polylines(GameObject root, string identifier)
      : base(root, MakeGeometric(), identifier) {
    }

    public override void Update(Geometry geometry) {

      base.PreUpdate(geometry);

      if (DirtyLocation(geometry)) {

        DestroyChildren();

        int n = geometry.Cnts.Sum();
        Debug.Assert(geometry.Posx.Count == n, "Number of endpoints must match number of x positions: " + obj.name);
        Debug.Assert(geometry.Posy.Count == n, "Number of endpoints must match number of y positions: " + obj.name);
        Debug.Assert(geometry.Posz.Count == n, "Number of endpoints must match number of z positions: " + obj.name);

        int j = 0;
        int k = geometry.Cnts[j];
        for (int i = 0; i < n; ++i) {

          if (i + 1 == k) {
            if (++j < geometry.Cnts.Count)
              k += geometry.Cnts[j];
            continue;
          }

          GameObject line = GameObject.CreatePrimitive(useBoxes ? PrimitiveType.Cube : PrimitiveType.Cylinder);
//        AddTrigger(line); // FIXME: Why isn't this necessary?
          line.transform.parent = obj.transform;

          Vector3[] locations = new Vector3[]{
            new Vector3((float) geometry.Posx[i  ], (float) geometry.Posy[i  ], (float) geometry.Posz[i  ]),
            new Vector3((float) geometry.Posx[i+1], (float) geometry.Posy[i+1], (float) geometry.Posz[i+1])
          };
          Vector3 midpoint = (locations[0] + locations[1]) / 2;
          Vector3 displacement = locations[1] - locations[0];

          line.transform.localPosition = midpoint;
          { // TODO: Replace with a pure quaternion computation.
            line.transform.localRotation = Quaternion.LookRotation(displacement);
            line.transform.Rotate(90, 0, 0);
          }
          line.transform.localScale = new Vector3(1, displacement.magnitude / (useBoxes ? 1 : 2), 1);

        }

      }

      if (DirtyLocation(geometry) || DirtySize(geometry)) {
        float radius = size / 2;
        foreach (Transform line in obj.transform) 
          line.transform.localScale = new Vector3(radius, line.transform.localScale.y, radius);
      }

      base.PostUpdate(geometry);

    }

  }
    
  public class Rectangles : Element {

    public Rectangles(GameObject root, string identifier)
      : base(root, MakeGeometric(), identifier) {
    }

    public override void Update(Geometry geometry) {

      base.PreUpdate(geometry);

      if (DirtyLocation(geometry)) {

        DestroyChildren();

        int n = geometry.Cnts.Sum();
        foreach (int i in geometry.Cnts)
          Debug.Assert(                i == 3, "Each rectangle must be defined by three points: "       + obj.name);
        Debug.Assert(geometry.Posx.Count == n, "Number of endpoints must match number of x positions: " + obj.name);
        Debug.Assert(geometry.Posy.Count == n, "Number of endpoints must match number of y positions: " + obj.name);
        Debug.Assert(geometry.Posz.Count == n, "Number of endpoints must match number of z positions: " + obj.name);

        for (int i = 0; i < n; i += 3) {

          GameObject rectangle = GameObject.CreatePrimitive(PrimitiveType.Quad);
//        AddTrigger(rectangle); // FIXME: Why isn't this necessary?
          rectangle.transform.parent = obj.transform;

          Vector3 origin     = new Vector3((float) geometry.Posx[i+0], (float) geometry.Posy[i+0], (float) geometry.Posz[i+0]);
          Vector3 horizontal = new Vector3((float) geometry.Posx[i+1], (float) geometry.Posy[i+1], (float) geometry.Posz[i+1]);
          Vector3 vertical   = new Vector3((float) geometry.Posx[i+2], (float) geometry.Posy[i+2], (float) geometry.Posz[i+2]);
          Quaternion q = Math.RotationFromPlane(Vector3.right, Vector3.up, origin, horizontal, vertical);
          float width = (horizontal - origin).magnitude;
          float height = (vertical - origin).magnitude;

          rectangle.transform.localPosition = origin + q * new Vector3(width / 2, height / 2, 0);
          rectangle.transform.localRotation = q;
          rectangle.transform.localScale = new Vector3(width, height, 1);

          rectangle = GameObject.CreatePrimitive(PrimitiveType.Quad);
          rectangle.transform.parent = obj.transform;

          q = Math.RotationFromPlane(Vector3.right, Vector3.up, origin, vertical, horizontal);

          width = (horizontal - origin).magnitude;
          rectangle.transform.localPosition = origin + q * new Vector3(height / 2, width / 2, 0);
          rectangle.transform.localRotation = q;
          rectangle.transform.localScale = new Vector3(height, width, 1);

        }

      }

      if (DirtyLocation(geometry) || DirtySize(geometry)) {
        foreach (Transform child in obj.transform)
          child.localScale = new Vector3(child.localScale.x, child.localScale.y, size / 2);
      }

      base.PostUpdate(geometry);

    }

  }
  
  public class Label : Element {

    private static Material textMaterial = null;

    private static Font textFont = null;

    private static GameObject MakeTextObject() {
      GameObject obj = new GameObject();
      MeshRenderer meshRenderer = obj.AddComponent<MeshRenderer>();
      if (textMaterial == null)
        textMaterial = Resources.Load<Material>("font-material");
      meshRenderer.material = textMaterial;
      TextMesh textComponent = obj.AddComponent<TextMesh>();
      if (textFont == null)
        textFont = Resources.Load<Font>("NotoSans-Regular");
      textComponent.font = textFont;
      textComponent.alignment = TextAlignment.Left;
      textComponent.fontSize = 50;
      textComponent.transform.localScale = new Vector3(0.25f, 0.25f, 0.25f);
      return obj;
    }

    public Label(GameObject root, string identifier)
      : base(root, MakeTextObject(), identifier) {
    }

    public override void Update(Geometry geometry) {

      base.PreUpdate(geometry);

      if (DirtyLocation(geometry)) {

        Debug.Assert(geometry.Cnts.Count == 1, "Label must have one group of points: " + obj.name);
        Debug.Assert(geometry.Cnts[0]    == 3, "Label group must have three points: "  + obj.name);
        Debug.Assert(geometry.Posx.Count == 3, "Label must have three x positions: "   + obj.name);
        Debug.Assert(geometry.Posy.Count == 3, "Label must have three y positions: "   + obj.name);
        Debug.Assert(geometry.Posz.Count == 3, "Label must have three z positions: "   + obj.name);

        Vector3 origin     = new Vector3((float) geometry.Posx[0], (float) geometry.Posy[0], (float) geometry.Posz[0]);
        Vector3 horizontal = new Vector3((float) geometry.Posx[1], (float) geometry.Posy[1], (float) geometry.Posz[1]);
        Vector3 vertical   = new Vector3((float) geometry.Posx[2], (float) geometry.Posy[2], (float) geometry.Posz[2]);
        Quaternion q = Math.RotationFromPlane(Vector3.right, Vector3.up, origin, horizontal, vertical);

        TextMesh textComponent = obj.GetComponent<TextMesh>();
        textComponent.transform.localPosition = origin + q * new Vector3(- 0.1f * size, 1.4f * size, 0f);
        textComponent.transform.localRotation = q;
      }

      if (DirtyLocation(geometry) || DirtySize(geometry)) {
        TextMesh textComponent = obj.GetComponent<TextMesh>();
        textComponent.transform.localScale = new Vector3(0.25f * size, 0.25f * size, 0.25f * size);
      }

      if (DirtyText(geometry)) {
        TextMesh textComponent = obj.GetComponent<TextMesh>();
        textComponent.text = geometry.Text;
      }

      base.PostUpdate(geometry);

    }

  }

  public class Axis : Element {

    public Axis(GameObject root, string identifier)
      : base(root, GameObject.CreatePrimitive(PrimitiveType.Cylinder), identifier) {
    }

    private static Object arrowhead = null;

    public override void Update(Geometry geometry) {

      base.PreUpdate(geometry);

      if (DirtyLocation(geometry)) {

        Debug.Assert(geometry.Cnts.Count == 1, "Arrow must have one group of points: " + obj.name);
        Debug.Assert(geometry.Cnts[0]    == 2, "Arrow group must have two points: "    + obj.name);
        Debug.Assert(geometry.Posx.Count == 2, "Arrow must have two x positions: "     + obj.name);
        Debug.Assert(geometry.Posy.Count == 2, "Arrow must have two y positions: "     + obj.name);
        Debug.Assert(geometry.Posz.Count == 2, "Arrow must have two z positions: "     + obj.name);

        Vector3[] locations = new Vector3[]{
          new Vector3((float) geometry.Posx[0], (float) geometry.Posy[0], (float) geometry.Posz[0]),
          new Vector3((float) geometry.Posx[1], (float) geometry.Posy[1], (float) geometry.Posz[1])
        };
        Vector3 midpoint = (locations[0] + locations[1]) / 2;
        Vector3 displacement = locations[1] - locations[0];

        obj.transform.localPosition = midpoint;
        { // TODO: Replace with a pure quaternion computation.
          obj.transform.localRotation = Quaternion.LookRotation(displacement);
          obj.transform.Rotate(90, 0, 0);
        }
        obj.transform.localScale = new Vector3(1, displacement.magnitude / 2, 1);

        if (obj.transform.childCount == 0) {
          if (arrowhead == null)
            arrowhead = Resources.Load("arrowhead");
          GameObject glyph = (GameObject) Object.Instantiate(arrowhead, obj.transform, false); // FIXME: Avoid casting.
          foreach (MeshRenderer renderer in obj.GetComponentsInChildren<MeshRenderer>())
            renderer.material.color = color;
        }

      }

      if (DirtySize(geometry) || DirtyLocation(geometry)) {
        float radius = size / 2;
        obj.transform.localScale = new Vector3(radius, obj.transform.localScale.y, radius);
      }

      base.PostUpdate(geometry);

    }

  }
    
}
