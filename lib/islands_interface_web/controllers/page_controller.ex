defmodule IslandsInterfaceWeb.PageController do
  use IslandsInterfaceWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    redirect(conn, to: ~p"/redirect-test")
  end

  def redirect_test(conn, _params) do
    render(conn, :home, layout: false)
  end
end
