defmodule IslandsInterfaceWeb.GameChannel do
  use IslandsInterfaceWeb, :channel

  alias IslandsEngine.{Game, GameSupervisor}

  @impl true
  def join("game:" <> _player, _payload, socket) do
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("hello", payload, socket) do
    broadcast!(socket, "said_hello", payload)
    {:noreply, socket}
  end

  def handle_in("new_game", _payload, socket) do
    "game:" <> player = socket.topic

    case GameSupervisor.start_game(player) do
      {:ok, _pid} ->
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("add_player", player, socket) do
    case Game.add_player(via(socket.topic), player) do
      :ok ->
        broadcast!(socket, "player_added", %{message: "New player just joined: " <> player})
        {:noreply, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}

      :err ->
        {:reply, {:error, %{}}, socket}
    end
  end

  def handle_in("position_island", payload, socket) do
    %{"player" => player, "island" => island, "row" => row, "col" => col} = payload
    player = String.to_existing_atom(player)
    island = String.to_existing_atom(island)

    case Game.position_island(via(socket.topic), player, island, row, col) do
      :ok -> {:reply, :ok, socket}
      _ -> {:reply, :error, socket}
    end
  end

  def handle_in("set_islands", player, socket) do
    player = String.to_existing_atom(player)

    case Game.set_islands(via(socket.topic), player) do
      {:ok, board} ->
        broadcast!(socket, "player_set_islands", %{player: player})
        {:reply, {:ok, %{board: inspect(board)}}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("guess_coordinate", params, socket) do
    %{"player" => player, "row" => row, "col" => col} = params
    player = String.to_existing_atom(player)

    case Game.guess_coordinate(via(socket.topic), player, row, col) do
      {:hit, island, win} ->
        result = %{hit: true, island: island, win: win}

        broadcast!(socket, "player_guessed_coordinate", %{
          player: player,
          row: row,
          col: col,
          result: result
        })

        {:noreply, socket}

      {:miss, island, win} ->
        result = %{hit: false, island: island, win: win}

        broadcast!(socket, "player_guessed_coordinate", %{
          player: player,
          row: row,
          col: col,
          result: result
        })

        {:noreply, socket}

      :err ->
        {:reply, {:error, %{player: player, reason: "Not your turn."}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{player: player, reason: reason}}, socket}
    end
  end

  defp via("game:" <> player), do: Game.via_tuple(player)

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
