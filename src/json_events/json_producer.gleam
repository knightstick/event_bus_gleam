import gleam/json.{type Json}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import json_events/json_bus.{type Message as BusMessage, Event as BusEvent}

pub type State {
  State(bus: Subject(BusMessage))
}

pub type Message {
  Produce(Person)
}

pub type Person {
  Person(name: String, is_cool: Bool)
}

pub fn start(bus) {
  actor.start(State(bus), loop)
}

pub fn produce(producer, name: String) {
  name
  |> to_person
  |> Produce
  |> actor.send(producer, _)
}

fn loop(message: Message, state: State) {
  case message {
    Produce(data) -> {
      data
      |> to_json
      |> json.to_string
      |> BusEvent
      |> json_bus.publish(state.bus, _)
      actor.continue(state)
    }
  }
}

fn to_json(data: Person) -> Json {
  let Person(name, is_cool) = data
  json.object([#("name", json.string(name)), #("is-cool", json.bool(is_cool))])
}

fn to_person(name: String) {
  Person(name, True)
}
