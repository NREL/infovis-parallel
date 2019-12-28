package infovis


import (
  "context"
  "github.com/golang/glog"
  kafkA "github.com/segmentio/kafka-go"
)


type Kafka struct {
  label  Label
  in     ProtobufChannel
  out    ProtobufChannel
  done   DoneChannel
  reader *kafkA.Reader
  writer *kafkA.Writer
  offset int64
}


func NewKafka(label Label, broker string, start bool) *Kafka {

  readerConfig := kafkA.ReaderConfig{
    Brokers  : []string{broker},
    Topic    : label           ,
    Partition: 0               ,
    MinBytes : 1000            ,
    MaxBytes : 10000000        ,
  }
  writerConfig := kafkA.WriterConfig{
    Brokers  : readerConfig.Brokers,
    Topic    : readerConfig.Topic  ,
  }

  var kafka = Kafka {
    label : label                        ,
    in    : make(ProtobufChannel)        ,
    out   : make(ProtobufChannel)        ,
    done  : make(DoneChannel)            ,
    reader: kafkA.NewReader(readerConfig),
    writer: kafkA.NewWriter(writerConfig),
    offset: -1                           ,
  }

  go func() {
    defer kafka.reader.Close()
    if start {
      kafka.offset = -2
    }
    if err := kafka.reader.SetOffset(kafka.offset); err != nil {
      glog.Errorf("Kafka consumer %s encountered error: %v.\n", label, err)
      kafka.Exit()
    }
    kafka.offset = kafka.reader.Offset()
    for {
      select {
        case <-kafka.done:
          return
        default:
          message, err := kafka.reader.ReadMessage(context.Background())
          if err != nil {
            glog.Errorf("Kakfa consumer %s encountered error: %v.\n", label, err)
            kafka.Exit()
            break
          }
          buffer := message.Value
          glog.Infof("Kafka consumer %s read %v bytes.\n", label, len(buffer))
          select {
            case kafka.out <- buffer:
            case <-kafka.done:
              return
          }
      }
    }
  }()

  go func() {
    defer kafka.writer.Close()
    for {
      select {
        case buffer, ok := <-kafka.in:
          if !ok {
            glog.Errorf("Receive failed for Kafka producer %s.\n", label)
            kafka.Exit()
            break
          }
          err := kafka.writer.WriteMessages(context.Background(), kafkA.Message{Key: []byte{}, Value: buffer,})
          if err != nil {
            glog.Errorf("Kafka producer %s encountered error: %v.\n", label, err)
            kafka.Exit()
            break
          }
          glog.Infof("Kafka producer %s wrote %v bytes.\n", label, len(buffer))
        case <-kafka.done:
          return
      }
    }
  }()

  return &kafka

}


func (kafka *Kafka) Label() Label {
  return kafka.label
}


func (kafka *Kafka) In() *ProtobufChannel {
  return &kafka.in
}


func (kafka *Kafka) Out() *ProtobufChannel {
  return &kafka.out
}


func (kafka *Kafka) Reset() {
  if err := kafka.reader.SetOffset(kafka.offset); err != nil {
    glog.Errorf("Kafka consumer %s encountered error: %v.\n", kafka.label, err)
    kafka.Exit()
  }
}


func (kafka *Kafka) Exit() {
  close(kafka.done)
}


func (kafka *Kafka) Alive() bool {
  select {
    case <-kafka.done:
      return false
    default:
      return true
  }
}
