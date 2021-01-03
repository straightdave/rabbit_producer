defmodule MyProducer do
  use RabbitProducer, host: "192.168.99.100", key: "q1"
end

defmodule RabbitProducerTest do
  use ExUnit.Case
  doctest RabbitProducer

  test "greets the world" do
    assert 1 == 1
  end
end
