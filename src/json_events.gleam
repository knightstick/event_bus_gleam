import gleam/int
import gleam/io
import gleam/erlang/process.{sleep}
import json_events/json_bus
import json_events/json_consumer
import json_events/json_producer

pub fn main() {
  io.println("Starting...")

  let assert Ok(bus) = json_bus.start()
  let assert Ok(producer) = json_producer.start(bus)
  let assert Ok(_) = json_consumer.start(bus)

  producer_loop(producer, 0)
}

fn producer_loop(producer, n) {
  json_producer.produce(producer, "Chris " <> int.to_string(n))
  sleep(1000)
  producer_loop(producer, n + 1)
}
