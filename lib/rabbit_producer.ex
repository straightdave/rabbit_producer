defmodule RabbitProducer do
  @moduledoc """
  Splendid Rabbit Producer
  """

  defmodule State do
    @moduledoc """
    State contains variables used during Producer instance lifetime:
    * conn: connection
    * chan: channel
    * ex: exchange (name)
    * key: routing-key
    """
    defstruct stopped: false, conn: nil, chan: nil, ex: "", key: ""
  end

  defmacro __using__(args) do
    host = Keyword.get(args, :host, "localhost")
    port = Keyword.get(args, :port, 5672)
    ex = Keyword.get(args, :exchange, "")
    ex_type = Keyword.get(args, :exchange_type, :direct)
    key = Keyword.get(args, :key, "")

    quote do
      @me __MODULE__

      @host unquote(host)
      @port unquote(port)
      @ex unquote(ex)
      @ex_type unquote(ex_type)
      @key unquote(key)

      use GenServer

      def publish(payload) do
        send(@me, {:pub, payload})
      end

      def stop() do
        send(@me, :stop)
      end

      def start_link(opts) do
        opts = Keyword.put(opts, :name, @me)
        GenServer.start_link(@me, [], opts)
      end

      @impl GenServer
      def init(_) do
        case AMQP.Connection.open(host: @host, port: @port) do
          {:ok, conn} ->
            {:ok, chan} = AMQP.Channel.open(conn)

            if @ex != "" do
              AMQP.Exchange.declare(chan, @ex, @ex_type)
            end

            if @key != "" do
              AMQP.Queue.declare(chan, @key)
            end

            {:ok, %State{conn: conn, chan: chan, ex: @ex, key: @key}}

          {:error, reason} ->
            IO.puts("Failed to connect to Rabbit: #{reason}")
            {:stop, reason}

          _ ->
            {:stop, "Unknown Error"}
        end
      end

      @impl GenServer
      def handle_info({:pub, payload}, %State{} = state) when not state.stopped do
        AMQP.Basic.publish(state.chan, state.ex, state.key, payload)
        {:noreply, state}
      end

      @impl GenServer
      def handle_info(:stop, %State{} = state) do
        AMQP.Connection.close(state.conn)
        state.stopped = true
        {:noreply, state}
      end
    end
  end
end
