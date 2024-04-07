import gleam/io.{println}
import gleam/list
import gleam/string
import gleam/otp/actor.{type Next}
import gleam/erlang/process.{type Subject}

pub fn main() {
  let bus: Subject(BusMessage) = start_bus()
  let _consumer = start_consumer(bus)
  let producer: Subject(ProducerMessage) = start_producer(bus)

  produce(producer, "Hello, World1")
  produce(producer, "Hello, World2")
  produce(producer, "Hello, World3")

  process.sleep(10)
  print_processed(bus)
}

fn start_bus() -> Subject(BusMessage) {
  let assert Ok(bus) =
    actor.start(BusState(processed: [], callbacks: []), bus_loop)
  bus
}

fn start_consumer(bus: Subject(BusMessage)) -> Subject(ConsumerMessage) {
  let assert Ok(consumer) = actor.start(Nil, consumer_loop)
  subscribe_to_bus(bus, fn(data: BusData) {
    actor.send(consumer, EventHappened(data))
  })
  consumer
}

fn start_producer(bus: Subject(BusMessage)) -> Subject(ProducerMessage) {
  let assert Ok(producer) = actor.start(ProducerState(bus), producer_loop)
  producer
}

fn produce(producer: Subject(ProducerMessage), message: BusData) {
  actor.send(producer, Produce(message))
}

// TODO: JSON?
type BusData =
  String

type BusState {
  BusState(processed: List(BusData), callbacks: List(fn(BusData) -> Nil))
}

type BusMessage {
  State(Subject(BusState))
  Publish(BusData)
  Subscribe(fn(BusData) -> Nil)
}

fn bus_loop(message: BusMessage, state: BusState) -> Next(BusMessage, BusState) {
  case message {
    State(caller) -> {
      actor.send(caller, state)
      actor.continue(state)
    }
    Publish(data) -> {
      let new_state = bus_publish(state, data)
      actor.continue(new_state)
    }
    Subscribe(callback) -> {
      let new_state = bus_subscribe(state, callback)
      actor.continue(new_state)
    }
  }
}

fn publish_to_bus(bus: Subject(BusMessage), data: BusData) {
  actor.send(bus, Publish(data))
}

fn bus_publish(state: BusState, data: BusData) -> BusState {
  let BusState(processed, callbacks) = state
  let new_processed = [data, ..processed]
  bus_process_one(data, callbacks)
  BusState(new_processed, callbacks)
}

fn subscribe_to_bus(
  bus: Subject(BusMessage),
  callback: fn(BusData) -> Nil,
) -> Nil {
  actor.send(bus, Subscribe(callback))
}

fn bus_subscribe(state: BusState, callback: fn(BusData) -> Nil) -> BusState {
  let BusState(processed, callbacks) = state
  let new_callbacks = [callback, ..callbacks]
  BusState(processed, new_callbacks)
}

fn bus_process_one(data: BusData, callbacks: List(fn(BusData) -> Nil)) {
  callbacks
  |> list.each(fn(callback) { callback(data) })
}

fn print_processed(bus: Subject(BusMessage)) {
  let BusState(data, _) = actor.call(bus, State, 10)
  io.println("Processed: " <> string.inspect(data))
}

type ConsumerState =
  Nil

type ConsumerMessage {
  EventHappened(BusData)
}

fn consumer_loop(
  message: ConsumerMessage,
  state: ConsumerState,
) -> Next(ConsumerMessage, ConsumerState) {
  case message {
    EventHappened(data) -> {
      println("[EVENT]: " <> data)
      actor.continue(state)
    }
  }
}

type ProducerState {
  ProducerState(bus: Subject(BusMessage))
}

type ProducerMessage {
  Produce(BusData)
}

fn producer_loop(
  message: ProducerMessage,
  state: ProducerState,
) -> Next(ProducerMessage, ProducerState) {
  let ProducerState(bus) = state

  case message {
    Produce(message) -> {
      publish_to_bus(bus, message)
      actor.continue(state)
    }
  }
}
