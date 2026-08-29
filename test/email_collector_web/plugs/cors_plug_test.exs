defmodule EmailCollectorWeb.Plugs.CorsPlugTest do
  use EmailCollectorWeb.ConnCase

  alias EmailCollector.Accounts
  alias EmailCollector.Campaigns
  alias EmailCollectorWeb.Plugs.CorsPlug

  setup do
    {:ok, user} =
      Accounts.create_user(%{
        email: "cors@example.com",
        password: "pw1234",
        password_confirmation: "pw1234"
      })

    {:ok, campaign} =
      Campaigns.create_campaign(%{
        name: "CORS Test",
        user_id: user.id,
        allowed_origins: ["https://myapp.com", "http://localhost:3000"]
      })

    %{user: user, campaign: campaign}
  end

  defp build_plug_conn(method, campaign_id, origin \\ nil) do
    conn =
      Phoenix.ConnTest.build_conn(method, "/api/v1/emails/#{campaign_id}")
      |> Map.put(:path_params, %{"campaign_id" => campaign_id})

    if origin do
      Plug.Conn.put_req_header(conn, "origin", origin)
    else
      conn
    end
  end

  describe "OPTIONS preflight" do
    test "returns 200 with CORS headers for allowed origin", %{campaign: campaign} do
      conn =
        build_plug_conn("OPTIONS", campaign.id, "https://myapp.com")
        |> CorsPlug.call([])

      assert conn.halted
      assert conn.status == 200
      assert get_resp_header(conn, "access-control-allow-origin") == ["https://myapp.com"]
      assert get_resp_header(conn, "access-control-allow-methods") == ["POST, OPTIONS"]
      assert get_resp_header(conn, "access-control-allow-headers") == ["Content-Type, Accept"]
      assert get_resp_header(conn, "vary") == ["Origin"]
    end

    test "returns 200 with no CORS headers for disallowed origin", %{campaign: campaign} do
      conn =
        build_plug_conn("OPTIONS", campaign.id, "https://evil.com")
        |> CorsPlug.call([])

      assert conn.halted
      assert conn.status == 200
      assert get_resp_header(conn, "access-control-allow-origin") == []
    end

    test "returns 200 with no CORS headers when no origin", %{campaign: campaign} do
      conn =
        build_plug_conn("OPTIONS", campaign.id)
        |> CorsPlug.call([])

      assert conn.halted
      assert conn.status == 200
      assert get_resp_header(conn, "access-control-allow-origin") == []
    end
  end

  describe "POST with Origin header" do
    test "passes through and sets CORS headers for allowed origin", %{campaign: campaign} do
      conn =
        build_plug_conn("POST", campaign.id, "https://myapp.com")
        |> CorsPlug.call([])

      refute conn.halted
      assert get_resp_header(conn, "access-control-allow-origin") == ["https://myapp.com"]
      assert get_resp_header(conn, "vary") == ["Origin"]
    end

    test "passes through for localhost allowed origin", %{campaign: campaign} do
      conn =
        build_plug_conn("POST", campaign.id, "http://localhost:3000")
        |> CorsPlug.call([])

      refute conn.halted
      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:3000"]
    end

    test "halts with 403 for disallowed origin", %{campaign: campaign} do
      conn =
        build_plug_conn("POST", campaign.id, "https://evil.com")
        |> CorsPlug.call([])

      assert conn.halted
      assert conn.status == 403
    end

    test "halts with 403 for non-existent campaign" do
      conn =
        build_plug_conn("POST", "00000000-0000-0000-0000-000000000000", "https://myapp.com")
        |> CorsPlug.call([])

      assert conn.halted
      assert conn.status == 403
    end

    test "halts with 403 when campaign has no allowed origins", %{user: user} do
      {:ok, empty_campaign} =
        Campaigns.create_campaign(%{name: "Empty Origins", user_id: user.id})

      conn =
        build_plug_conn("POST", empty_campaign.id, "https://myapp.com")
        |> CorsPlug.call([])

      assert conn.halted
      assert conn.status == 403
    end
  end

  describe "POST without Origin header (direct/non-browser requests)" do
    test "passes through with no CORS headers", %{campaign: campaign} do
      conn =
        build_plug_conn("POST", campaign.id)
        |> CorsPlug.call([])

      refute conn.halted
      assert get_resp_header(conn, "access-control-allow-origin") == []
    end

    test "passes through even when campaign has no allowed origins", %{user: user} do
      {:ok, empty_campaign} =
        Campaigns.create_campaign(%{name: "Empty Origins 2", user_id: user.id})

      conn =
        build_plug_conn("POST", empty_campaign.id)
        |> CorsPlug.call([])

      refute conn.halted
    end
  end
end
