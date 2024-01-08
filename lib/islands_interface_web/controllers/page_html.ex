defmodule IslandsInterfaceWeb.PageHTML do
  use IslandsInterfaceWeb, :html

  embed_templates "page_html/*"

  def start_game_form(assigns) do
    assigns =
      assigns
      |> Map.put(:form, to_form(%{"name" => nil}))

    ~H"""
    <.simple_form for={@form} action={~p"/test"}>
      <.input field={@form[:name]} label="Name" />
      <:actions>
        <.button>Start Game</.button>
      </:actions>
    </.simple_form>
    """
  end
end
