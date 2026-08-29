defmodule EmailCollectorWeb.PageController do
  use EmailCollectorWeb, :controller

  alias EmailCollector.Accounts
  alias EmailCollector.Accounts.User

  def home(conn, _params) do
    base_url = EmailCollectorWeb.Endpoint.url()
    changeset = Accounts.change_user(%User{})
    render(conn, :home, layout: false, base_url: base_url, changeset: changeset)
  end
end
