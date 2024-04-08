import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor

pub type Message {
  Publish(Event)
  Subscribe(fn(Event) -> Nil)
}

pub type State {
  State(published: List(Event), callbacks: List(Callback))
}

pub type Event {
  Event(Data)
}

pub type Data =
  String

pub type Callback =
  fn(Event) -> Nil

pub fn start() {
  actor.start(State(published: [], callbacks: []), loop)
}

fn loop(message: Message, state: State) {
  let State(published, callbacks) = state
  case message {
    Publish(event) -> {
      // TODO: Function that could crash shouldn't crash the queue
      list.each(callbacks, fn(callback) { callback(event) })

      let new_state =
        State(published: [event, ..published], callbacks: callbacks)
      actor.continue(new_state)
    }
    Subscribe(callback) -> {
      let new_state =
        State(callbacks: [callback, ..callbacks], published: published)
      actor.continue(new_state)
    }
  }
}

pub fn publish(bus: Subject(Message), event: Event) {
  actor.send(bus, Publish(event))
}

pub fn subscribe(bus: Subject(Message), callback: fn(Event) -> Nil) {
  actor.send(bus, Subscribe(callback))
}
