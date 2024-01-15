defmodule IslandsInterfaceWeb.IslandsLive do
  use IslandsInterfaceWeb, :live_view

  alias IslandsEngine.{Game, GameSupervisor}

  embed_templates "islands_states/*"

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       game_state: :initialized,
       game_pid: nil,
       room_name: "",
       player_name: "",
       player1: nil,
       player2: nil,
       game_board: Enum.map(1..10, fn _ -> Enum.map(1..10, fn _ -> 0 end) end)
     )}
  end

  attr :room_name, :string, required: true
  attr :player_name, :string, required: true
  def join_game_form(assigns)

  def set_islands(assigns)

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

    IO.puts(inspect(player1))

    socket
    |> assign(game_pid: game_pid)
    |> assign(game_state: game_state.rules.state)
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
