defmodule WPSWeb.PageSpeedLive do
  use WPSWeb, :live_view
  require Logger

  alias WPS.Browser

  @max_req_per_min_per_host 10
  @max_all_req_per_min 100
  @browser_timeout 30_000

  def render(assigns) do
    ~H"""
    <div class="py-8">
      <h2 class="mx-auto max-w-2xl text-center text-3xl font-bold tracking-tight text-black sm:text-4xl">
        Check your website now!
      </h2>
      <p :if={!@ref} class="mx-auto mt-2 max-w-xl text-center text-lg leading-8 text-gray-700">
        Measure your website's performance around the globe!
      </p>
      <div class="space-y-5">
        <form
          :if={!@ref}
          id="url-form"
          class="mx-auto mt-10 flex max-w-md gap-x-4"
          phx-change="validate"
          phx-submit="go"
        >
          <label for="email-address" class="sr-only">URL</label>
          <input
            id="url"
            name="url"
            type="text"
            value={@form[:url].value}
            required
            class="min-w-0 flex-auto rounded-md border-0 bg-black/5 px-3.5 py-2 text-black shadow-sm ring-1 ring-inset ring-blue/10 focus:ring-2 focus:ring-inset focus:ring-blue sm:text-md sm:leading-6 disabled:opacity-80"
            placeholder="Enter your URL"
            disabled={!!@ref}
            phx-mounted={JS.focus()}
          />
          <button
            type="submit"
            class="flex-none rounded-md bg-black px-3.5 py-2.5 text-md font-semibold text-gray-100 shadow-sm hover:bg-gray-900 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue disabled:bg-gray-400"
            disabled={!!@ref}
          >
            Go!
          </button>
        </form>

        <div :if={!@ref} class="mx-auto border-b border-gray-300"></div>

        <div class="mt-10 divide-y divide-black/5">
          <div :if={@ref} class="flex items-center justify-center gap-x-6">
            <a href={@uri} class="text-lg font-semibold leading-6 text-black" target="_blank">
              Results for <span class="text-gray-600 font-normal"><%= @uri %></span>
              <span aria-hidden="true">→</span>
            </a>
            <button
              phx-click="reset"
              class="flex-none rounded-md bg-black px-3.5 py-2.5 text-md font-semibold text-gray-100 shadow-sm hover:bg-gray-900 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue disabled:bg-gray-400"
            >
              Reset
            </button>
          </div>
          <ul id="timings" phx-update="stream" role="list" class="mt-10 divide-y divide-black/5">
            <li
              :for={{id, timing} <- @streams.timings}
              id={id}
              class="relative flex items-center space-x-10 py-4"
            >
              <div class="min-w-0 flex-auto">
                <div class="flex items-center gap-x-3">
                  <div
                    :if={timing.status in [:loading, :awaiting_session]}
                    class="flex-none rounded-full p-1 text-gray-500 bg-gray-900/15 animate animate-pulse"
                  >
                    <div class="h-3 w-3 rounded-full bg-current"></div>
                  </div>
                  <div
                    :if={timing.status == :complete && timing.http_status == 200}
                    class="flex-none rounded-full p-1 text-green-400 bg-green-400/15"
                  >
                    <div class="h-3 w-3 rounded-full bg-current"></div>
                  </div>
                  <div
                    :if={
                      (timing.status == :error || timing.status == :complete) &&
                        timing.http_status != 200
                    }
                    class="flex-none rounded-full p-1 text-rose-400 bg-rose-400/15"
                  >
                    <div class="h-3 w-3 rounded-full bg-current"></div>
                  </div>
                  <h2 class="min-w-0 text-md font-semibold leading-6 text-black">
                    <span class="flex gap-x-2">
                      <span class="truncate"><%= region_text(timing.region) %></span>
                      <span class="text-gray-600 hidden md:block">
                        <.icon name="hero-paper-airplane" class="w-5 h-5" />
                      </span>
                      <span class="whitespace-nowrap font-normal text-gray-600 hidden md:block">
                        <%= URI.parse(timing.browser_url).host %>
                      </span>
                      <span class="absolute inset-0"></span>
                    </span>
                  </h2>
                </div>
                <div class="mt-3 flex items-center gap-x-2.5 text-xs leading-5 text-gray-600">
                  <p class="truncate"><%= status_text(timing) %></p>
                  <svg
                    :if={timing.status == :complete}
                    viewBox="0 0 2 2"
                    class="h-0.5 w-0.5 flex-none fill-gray-600"
                  >
                    <circle cx="1" cy="1" r="1" />
                  </svg>
                  <p
                    :if={domint = Browser.Timing.dom_interactive_time(timing)}
                    class="whitespace-nowrap"
                  >
                    DOM interactive <%= domint %>ms
                  </p>
                  <svg
                    :if={timing.status == :complete}
                    viewBox="0 0 2 2"
                    class="h-0.5 w-0.5 flex-none fill-gray-600"
                  >
                    <circle cx="1" cy="1" r="1" />
                  </svg>
                  <p :if={timing.transfered_bytes > 0} class="whitespace-nowrap">
                    <%= transfered_size(timing) %>
                  </p>
                </div>
              </div>
              <div class="min-w-[100px]">
                <span
                  :if={timing.status == :complete}
                  class="rounded-full flex-none py-2 px-2 text-md font-medium ring-1 ring-inset text-indigo-400 bg-indigo-400/10 ring-indigo-400/30"
                >
                  <img
                    :if={src = badge_src(timing.region)}
                    class="relative inline mr-1 -top-0.5 left-0 w-5 h-5"
                    src={src}
                    title={region_text(timing.region)}
                  />
                  <%= timing.loaded %>ms
                </span>
              </div>
            </li>
          </ul>
        </div>
      </div>

      <div>
        <p class="mx-auto mt-4 max-w-2xl text-center text-sm text-gray-400">
        ⚡Powered by <a href="https://pagertree.com/" target="_blank" class="text-blue-600">PagerTree</a>
        </p>
      </div>

    </div>
    """
  end

  def mount(_params, _session, socket) do
    default_url = ""

    socket =
      socket
      |> assign(ref: nil, uri: URI.parse(default_url), form: to_form(%{"url" => default_url}))
      |> stream_configure(:timings, dom_id: &"timing-#{&1.region}")
      |> stream(:timings, [])
      # |> simulate_results("https://phoenixframework.org")

    {:ok, socket}
  end

  defp simulate_results(socket, url) do
    uri = URI.parse(url)

    timings = [
      %Browser.Timing{
        status: :complete,
        url: url,
        browser_url: url,
        loaded: 2500,
        meta: %{},
        region: "iad"
      },
      %Browser.Timing{
        status: :loading,
        url: url,
        browser_url: url,
        loaded: 0,
        meta: %{},
        region: "syd"
      },
      %Browser.Timing{
        status: :error,
        url: url,
        browser_url: url,
        loaded: 0,
        meta: %{},
        region: "arn"
      }
    ]

    socket
    |> assign(ref: :simulated, uri: uri, form: to_form(%{"url" => url}))
    |> stream(:timings, timings, reset: true)
  end

  def handle_event("reset", _, socket) do
    {:noreply,
     socket
     |> clear_flash()
     |> cancel_async(:timing)
     |> assign(ref: nil, uri: nil, form: to_form(%{"url" => ""}))
     |> stream(:timings, [], reset: true)}
  end

  def handle_event("validate", %{"url" => url}, socket) do
    {:noreply, socket |> clear_flash() |> assign(form: to_form(%{"url" => url}))}
  end

  def handle_event("go", %{"url" => url}, socket) do
    %{ref: nil} = socket.assigns

    case validate_url(url) do
      {:ok, uri} ->
        validated_url = URI.to_string(uri)
        ref = make_ref()
        parent = self()

        node_timings =
          for {region, meta} <- WPS.Members.list(), %{node: node} = meta, into: %{} do
            {node, Browser.Timing.build(validated_url, region)}
          end

        {:noreply,
         socket
         |> clear_flash()
         |> assign(ref: ref, uri: uri, form: to_form(%{"url" => validated_url}))
         |> stream(:timings, Map.values(node_timings), reset: true)
         |> start_async(:timing, fn ->
           nodes = Enum.map(node_timings, fn {node, _} -> node end)
           :erpc.multicall(nodes, fn -> safe_timed_nav(node_timings[node()], parent, ref) end)
         end)}

      {:error, :rate_limited} ->
        {:noreply, put_flash(socket, :error, "Too many requests, please try again later")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Please provide a valid URL")}
    end
  end

  def handle_async(:timing, result, socket) do
    case result do
      {:ok, results} ->
        for result <- results do
          case result do
            {:ok, _} -> :ok
            error -> Logger.error(inspect(error))
          end
        end

      {:exit, reason} ->
        Logger.error(inspect({:exit, reason}))
    end

    {:noreply, socket}
  end

  def handle_info({ref, {:loading, %Browser.Timing{} = timing}}, socket) do
    case socket.assigns.ref do
      ^ref -> {:noreply, stream_insert(socket, :timings, timing)}
      _ref -> {:noreply, socket}
    end
  end

  def handle_info({ref, {:complete, %Browser.Timing{} = timing}}, socket) do
    case socket.assigns.ref do
      ^ref -> {:noreply, stream_insert(socket, :timings, timing)}
      _ref -> {:noreply, socket}
    end
  end

  def handle_info({ref, {:error, {_, %Browser.Timing{} = timing}}}, socket) do
    case socket.assigns.ref do
      ^ref -> {:noreply, stream_insert(socket, :timings, timing)}
      _ref -> {:noreply, socket}
    end
  end

  def validate_url(url) do
    url = String.trim(url)
    # Ensure the URL has a protocol and default to http if missing
    uri =
      case URI.parse(url) do
        %URI{scheme: nil} -> URI.parse("http://#{url}")
        %URI{} = uri -> uri
      end

    with true <- uri.scheme in ["http", "https"],
         false <- uri.host in ["localhost", "", nil],
         # Exclude .local/.internal hostnames
         false <- String.contains?(uri.host, ~w(.internal .local)),
         # ensure not ipv4 or ipv6 address
         {:error, _} <- :inet.parse_address(uri.host),
         # Ensure there's a TLD
         true <- Regex.match?(~r/\.[a-zA-Z]{2,}$/, uri.host),
         # apply rate limites
         {:ok, _} <- WPS.RateLimiter.inc(uri.host, @max_req_per_min_per_host),
         {:ok, _} <- WPS.RateLimiter.inc(:all_hosts, @max_all_req_per_min) do
      {:ok, uri}
    else
      {:error, :rate_limited} ->
        {:error, :rate_limited}

      _ ->
        {:error, :invalid_url}
    end
  end

  def safe_timed_nav(%Browser.Timing{} = timing, parent, ref) do
    FLAME.call(WPS.BrowserRunner, fn ->
      timing = Browser.Timing.loading(timing)
      send(parent, {ref, {:loading, timing}})

      case Browser.time_navigation(timing, @browser_timeout) do
        {:ok, %Browser.Timing{} = timing} ->
          send(parent, {ref, {:complete, timing}})

        {:error, {reason, %Browser.Timing{} = timing}} ->
          send(parent, {ref, {:error, {reason, timing}}})

        {:error, reason} ->
          send(parent, {ref, {:error, {reason, Browser.Timing.error(timing)}}})
      end
    end)
  end

  defp status_text(%Browser.Timing{status: :loading}), do: "Loading page"
  defp status_text(%Browser.Timing{status: :awaiting_session}), do: "Starting browser"
  defp status_text(%Browser.Timing{status: :error}), do: "Failed to load page"
  defp status_text(%Browser.Timing{status: :complete, http_status: stat}), do: "#{stat} Complete"

  defp transfered_size(%Browser.Timing{transfered_bytes: bytes}) do
    kb = trunc(bytes / 1024)

    cond do
      kb < 1024 -> "#{kb} kb"
      kb >= 1024 -> "#{Float.round(kb / 1024, 2)} mb"
    end
  end
end
