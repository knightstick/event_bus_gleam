import gleam/io
import gleam/result
import gleam/string
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import modules/event_bus.{
  type Event as BusEvent, type Message as BusMessage, Event as BusEvent,
}

type State {
  State(bus: Subject(BusMessage))
}

pub type Message {
  Event(BusEvent)
}

pub fn start(bus) {
  actor.start(State(bus: bus), loop)
  |> result.try(fn(consumer) {
    subscribe(bus, reply(consumer, _))
    Ok(consumer)
  })
}

fn loop(message: Message, state: State) {
  case message {
    Event(event) -> {
      process_event(event, state)
      actor.continue(state)
    }
  }
}

fn subscribe(bus: Subject(BusMessage), callback: fn(BusEvent) -> Nil) {
  event_bus.subscribe(bus, callback)
}

fn process_event(event: BusEvent, _state: State) {
  let BusEvent(data) = event
  io.println("[EVENT]: " <> string.inspect(data))
}

fn reply(consumer, event) {
  actor.send(consumer, Event(event))
}
