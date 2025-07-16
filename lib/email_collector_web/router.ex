defmodule EmailCollectorWeb.Router do
  use EmailCollectorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EmailCollectorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug EmailCollectorWeb.AuthPlug, :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug EmailCollectorWeb.Plugs.ApiAuthPlug
  end

  scope "/", EmailCollectorWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/profile", UserController, :show

    # Campaign CRUD routes
    get "/campaigns/new", CampaignController, :new
    post "/campaigns", CampaignController, :create
    get "/campaigns/:id", CampaignController, :show
    get "/campaigns/:id/edit", CampaignController, :edit
    put "/campaigns/:id", CampaignController, :update
    patch "/campaigns/:id", CampaignController, :update
    delete "/campaigns/:id", CampaignController, :delete
    get "/campaigns/:id/download", CampaignController, :download_csv
  end

  scope "/auth", EmailCollectorWeb do
    pipe_through :browser

    get "/new", AuthController, :new
    post "/", AuthController, :create
    get "/login", AuthController, :login
    post "/login", AuthController, :authenticate
    delete "/logout", AuthController, :logout

    # Password reset
    get "/forgot-password", AuthController, :forgot_password
    post "/forgot-password", AuthController, :send_reset_link
    get "/reset-password", AuthController, :reset_password
    post "/reset-password", AuthController, :update_password
  end

  scope "/api/v1", EmailCollectorWeb.Api do
    pipe_through :api

    post "/emails/:campaign_id", EmailController, :create
    get "/emails/:campaign_id", EmailController, :index
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:email_collector, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EmailCollectorWeb.Telemetry
    end
  end
end
