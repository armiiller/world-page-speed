defmodule WPSWeb.Router do
  use WPSWeb, :router

  # A plug to set a CSP allowing embedding only on certain domains.
  # This is just an example, actual implementation depends on project
  # requirements.
  defp allow_iframe(conn, _opts) do
    conn
    |> delete_resp_header("x-frame-options")
    |> put_resp_header(
      "content-security-policy",
      "frame-ancestors 'self' https://pagertree.com https://pagertree-1.ngrok.io https://app.umso.com" # Add your list of allowed domain(s) here
    )
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WPSWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # Similar to default `:browser` pipeline, but with one more plug
  # `:allow_iframe` to securely allow embedding in an iframe.
  pipeline :embedded do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WPSWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :allow_iframe
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WPSWeb do
    pipe_through :browser

    live "/", PageSpeedLive, :show
  end

  # Configure LiveView routes using the `:embedded` pipeline
  # and custom `embedded.html.heex` layout.
  scope "/embed", WPSWeb do
    pipe_through [:embedded]

    live_session :embedded,
      layout: {WPSWeb.Layouts, :embedded} do
      live "/", PageSpeedLive, :show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", WPSWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:wps, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WPSWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
