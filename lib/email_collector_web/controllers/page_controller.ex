defmodule EmailCollectorWeb.PageController do
  use EmailCollectorWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    base_url = EmailCollectorWeb.Endpoint.url()
    render(conn, :home, layout: false, base_url: base_url)
  end
end
