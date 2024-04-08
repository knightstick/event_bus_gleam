import gleam/list
import gleam/otp/actor

pub type Message {
  Publish(Event)
  Subscribe(Callback)
}

pub type Data =
  String

pub opaque type State {
  State(published: List(Event), callbacks: List(Callback))
}

pub type Event {
  Event(Data)
}

pub type Callback =
  fn(Event) -> Nil

pub fn start() {
  actor.start(new_state(), loop)
}

pub fn publish(bus, event) {
  actor.send(bus, Publish(event))
}

pub fn subscribe(bus, callback) {
  actor.send(bus, Subscribe(callback))
}

fn loop(message: Message, state: State) {
  let State(published, callbacks) = state
  case message {
    Publish(event) -> {
      list.each(callbacks, fn(callback) { callback(event) })
      let new_state = State([event, ..published], callbacks)
      actor.continue(new_state)
    }
    Subscribe(callback) -> {
      let new_state = State(published, [callback, ..callbacks])
      actor.continue(new_state)
    }
  }
}

fn new_state() -> State {
  State([], [])
}
