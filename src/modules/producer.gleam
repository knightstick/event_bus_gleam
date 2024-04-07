import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import modules/event_bus.{
  type Data as BusData, type Message as BusMessage, Event as BusEvent,
}

type State {
  State(bus: Subject(BusMessage))
}

pub type Message {
  Produce(BusData)
}

pub fn start(bus) {
  actor.start(State(bus: bus), loop)
}

fn loop(message: Message, state: State) {
  case message {
    Produce(data) -> {
      event_bus.publish(state.bus, BusEvent(data))
      actor.continue(state)
    }
  }
}

pub fn produce(producer, data: BusData) {
  actor.send(producer, Produce(data))
}
