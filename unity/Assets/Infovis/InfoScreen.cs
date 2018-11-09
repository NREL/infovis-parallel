using UnityEngine;

using Debug = UnityEngine.Debug;
using Text = UnityEngine.UI.Text;


namespace Infovis {

  public class InfoScreen : MonoBehaviour {

    public Text infoText;

    public GameObject selectionVisualizer;

    void Start() {

      ShowMessage("Infovis Parallel\nws://" + Network.player.ipAddress + ":8080", 5f);

    }

    void Update() {

      if (turnedOn && Time.time > turnOff) {
        infoText.enabled = false;
        turnedOn = false;
      }

    }

    private bool turnedOn = true;

    private float turnOff = 0;

    public void ShowMessage(string text, float duration) {
      turnOff = Time.time + duration;
      if (text != infoText.text)
        infoText.text = text;
      if (!turnedOn) {
        infoText.enabled = true;
        turnedOn = true;
      }
    }

  }

}
