defmodule IslandsInterfaceWeb.HelloHTML do
  use IslandsInterfaceWeb, :html

  embed_templates "hello_html/*"

  attr :messenger, :string

  def greet(assigns) do
    ~H"""
    <h2>Hello World, from <%= @messenger %>!</h2>
    """
  end
end
