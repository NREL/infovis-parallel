package infovis


import (
  "context"
  "log"
  kafkA "github.com/segmentio/kafka-go"
)


type Kafka struct {
  label  Label
  in     ProtobufChannel
  out    ProtobufChannel
  exit   bool
  reader *kafkA.Reader
  writer *kafkA.Writer
  offset int64
}


func NewKafka(label Label, broker string, start bool, verbose bool) *Kafka {

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
    exit  : false                        ,
    reader: kafkA.NewReader(readerConfig),
    writer: kafkA.NewWriter(writerConfig),
    offset: -1                           ,
  }

  go func() {
    if start {
      kafka.offset = -2
    }
    if err := kafka.reader.SetOffset(kafka.offset); err != nil {
      log.Printf("Kafka consumer %s encountered error: %v.\n", label, err)
      kafka.exit = true
    }
    kafka.offset = kafka.reader.Offset()
    for !kafka.exit {
      message, err := kafka.reader.ReadMessage(context.Background())
      if err != nil {
        log.Printf("Kakfa consumer %s encountered error: %v.\n", label, err)
        kafka.exit = true
        break
      }
      buffer := message.Value
      if verbose {
        log.Printf("Kafka consumer %s read %v bytes.\n", label, len(buffer))
      }
      kafka.out <- buffer
    }
    kafka.reader.Close()
  }()

  go func() {
    for !kafka.exit {
      buffer, okay := <-kafka.in
      if !okay {
        log.Printf("Receive failed for Kafka producer %s.\n", label)
        kafka.exit = true
        break
      }
      err := kafka.writer.WriteMessages(context.Background(), kafkA.Message{Key: []byte{}, Value: buffer,})
      if err != nil {
        log.Printf("Kafka producer %s encountered error: %v.\n", label, err)
        kafka.exit = true
        break
      }
      if verbose {
        log.Printf("Kafka producer %s wrote %v bytes.\n", label, len(buffer))
      }
    }
    kafka.writer.Close()
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
    log.Printf("Kafka consumer %s encountered error: %v.\n", kafka.label, err)
    kafka.exit = true
  }
}


func (kafka *Kafka) Exit() {
  kafka.exit = true
}


func (kafka *Kafka) Alive() bool {
  return !kafka.exit
}
