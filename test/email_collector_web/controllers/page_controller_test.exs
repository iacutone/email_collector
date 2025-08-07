defmodule EmailCollectorWeb.PageControllerTest do
  use EmailCollectorWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Email Collection, Zero Bloat"
  end
end
