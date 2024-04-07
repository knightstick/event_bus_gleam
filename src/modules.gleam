import gleam/int
import gleam/erlang/process.{sleep}
import modules/consumer
import modules/event_bus
import modules/producer

pub fn main() {
  let assert Ok(bus) = event_bus.start()
  let assert Ok(_consumer) = consumer.start(bus)
  let assert Ok(a_producer) = producer.start(bus)

  producer_loop(a_producer, 0)
}

fn producer_loop(a_producer, n) {
  producer.produce(a_producer, "Hello, World " <> int.to_string(n))
  sleep(1000)
  producer_loop(a_producer, n + 1)
}
