import gleam/dynamic
import gleam/io
import gleam/json
import gleam/result
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import json_events/json_bus.{
  type Event as BusEvent, type Message as BusMessage, Event as BusEvent,
}
import json_events/json_producer.{type Person, Person}

pub type Message {
  Event(BusEvent)
}

pub type State {
  State(bus: Subject(BusMessage))
}

pub fn start(bus) {
  actor.start(State(bus), loop)
  |> result.try(fn(consumer) {
    json_bus.subscribe(bus, reply(consumer, _))
    Ok(consumer)
  })
}

fn loop(message: Message, state: State) {
  case message {
    Event(bus_event) -> {
      process_event(bus_event, state)
      actor.continue(state)
    }
  }
}

fn reply(consumer, event) {
  actor.send(consumer, Event(event))
}

fn process_event(bus_event, _state) {
  let BusEvent(string) = bus_event

  case deserialize(string) {
    Ok(person) -> io.println("[EVENT]: " <> person)
    Error(error) -> {
      let message = case error {
        InvalidJson -> "Invalid JSON"
        InvalidPerson -> "Invalid person"
      }

      io.println("[ERROR]: Failed to decode event: " <> message)
    }
  }
}

fn deserialize(string) {
  use json <- result.try(do_decode(string))
  use person <- result.try(do_decode_person(json))

  Ok(display(person))
}

pub type DecodeError {
  InvalidJson
  InvalidPerson
}

fn do_decode(string) -> Result(_, DecodeError) {
  json.decode(string, Ok)
  |> result.map_error(fn(_) { InvalidJson })
}

fn do_decode_person(json) -> Result(_, DecodeError) {
  decode_person(json)
  |> result.map_error(fn(_) { InvalidPerson })
}

fn decode_person(data) {
  let decoder =
    dynamic.decode2(
      Person,
      dynamic.field("name", dynamic.string),
      dynamic.field("is-cool", dynamic.bool),
    )

  decoder(data)
}

fn display(person: Person) {
  "Person: " <> person.name
}
