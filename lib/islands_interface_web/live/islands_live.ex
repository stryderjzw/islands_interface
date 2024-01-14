defmodule IslandsInterfaceWeb.IslandsLive do
  use IslandsInterfaceWeb, :live_view

  alias IslandsEngine.{Game, GameSupervisor}

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       game_started: false,
       game_pid: nil,
       room_name: "",
       player_name: "",
       player1: nil,
       player2: nil
     )}
  end

  attr :room_name, :string, required: true
  attr :player_name, :string, required: true

  def join_game_form(assigns) do
    ~H"""
    <form id="join_game_form" phx-submit="form_submitted">
      <div class="mb-4">
        <label for="player_name" class="block text-sm font-semibold text-gray-700">Player Name</label>
        <input
          type="text"
          id="player_name"
          name="player_name"
          value={@player_name}
          required
          class="mt-1 block w-full px-3 py-2 bg-white border rounded-md text-gray-700 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50"
        />
      </div>
      <div class="mb-6">
        <label for="room_name" class="block text-sm font-semibold text-gray-700">
          Room Name (optional)
        </label>
        <input
          type="text"
          id="room_name"
          name="room_name"
          value={@room_name}
          class="mt-1 block w-full px-3 py-2 bg-white border rounded-md text-gray-700 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50"
        />
      </div>
      <div class="flex justify-center">
        <button
          type="submit"
          class="px-6 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none focus:bg-blue-700"
        >
          Join Game
        </button>
      </div>
    </form>
    """
  end

  def handle_event("form_submitted", params, socket) do
    %{"room_name" => room_name, "player_name" => player_name} = params
    room_name = if room_name == "", do: player_name, else: room_name

    case GameSupervisor.start_game(room_name) do
      {:ok, game_pid} ->
        socket = initialize_or_reconnect_game(socket, game_pid, player_name)
        {:noreply, socket}

      {:error, {:already_started, game_pid}} ->
        socket = initialize_or_reconnect_game(socket, game_pid, player_name)
        {:noreply, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  defp initialize_or_reconnect_game(socket, game_pid, player_name) do
    game_state = :sys.get_state(game_pid)

    game_state =
      if game_state.rules.state == :initialized,
        do: put_in(game_state[:player2][:name], "Player 2"),
        else: game_state

    player1 = game_state.player1

    player2 =
      if game_state.rules.state == :initialized and player_name != player1.name do
        add_player2(game_pid, player_name)
      else
        game_state.player2
      end

    socket
    |> assign(game_pid: game_pid)
    |> assign(game_started: true)
    |> assign(:player1, player1)
    |> assign(:player2, player2)
  end

  defp add_player2(game_pid, player_name) do
    case Game.add_player(game_pid, player_name) do
      :ok ->
        game_state = :sys.get_state(game_pid)
        game_state.player2

      {:err, :invalid_state} ->
        {:err, :invalid_state}
    end
  end
end
