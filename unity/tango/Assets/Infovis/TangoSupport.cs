using Google.Protobuf.Collections;
using Infovis.Protobuf;
using UnityEngine;

using Convert = System.Convert;


namespace Infovis {

  public class TangoSupport : MonoBehaviour {

    public Program program;

    public GameObject camera;

    public double deltaReport = 5;

    private double nextReport = 0;

    void Update() {

      if (Input.GetKey(KeyCode.Escape)) {

        AndroidHelper.AndroidQuit();

      } else if (Input.GetMouseButtonDown(0)) {

        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition); 
        Quaternion rotation = Quaternion.LookRotation(ray.direction);

        Response response = new Response {
          Message = "Time: " + Time.time + "s",
          Toolloc = new Location {
            Posx = ray.origin.x,
            Posy = ray.origin.y,
            Posz = ray.origin.z,
            Rotw = rotation.w,
            Rotx = rotation.x,
            Roty = rotation.y,
            Rotz = rotation.z,
          },
        };

        RaycastHit hit;
        if (Physics.Raycast(ray, out hit))
          for (GameObject obj = hit.collider.gameObject; gameObject != null; obj = obj.transform.parent.gameObject)
            if (obj.tag == "infovis") {
              long identifier = Convert.ToInt64(obj.name);
              response.Select.Add(identifier);
              response.Deselect.Add(identifier);
              Element element = program.Find(identifier);
              if (element != null && element.text != "")
                program.Display(element.text, 1f);
              break;
            }

        program.Broadcast(response);

      } else if (Time.time >= nextReport) {

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
