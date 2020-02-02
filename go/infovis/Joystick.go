package infovis


import (
  "fmt"
  "time"
  "github.com/simulatedsimian/joystick"
)


func NewJoystick(jsid int) {

  js, err := joystick.Open(jsid)
  if err != nil {
    panic(err)
  }

  fmt.Printf("Joystick Name: %s\n", js.Name())
  fmt.Printf("   Axis Count: %d\n", js.AxisCount())
  fmt.Printf(" Button Count: %d\n", js.ButtonCount())

  for {
  state, err := js.Read()
  if err != nil {
    panic(err)
  }

    fmt.Printf("State: %v\n", state)
    time.Sleep(100 * time.Millisecond)
  }

  js.Close()

}
