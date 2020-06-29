defmodule LiveProps.LiveView do
  @moduledoc ~S'''
  Use this module inside a Phoenix.LiveView to add state management functionality to your
  LiveViews

  ### LiveView Lifecycle with LiveProps

  LiveProps injects lightweight `c:Phoenix.LiveView.mount/3` and
  `c:Phoenix.LiveView.handle_info/2` callbacks to help manage state.

  The lifecycle of the injected mount statement looks like this:

      assign_default_states(socket) ->
      user_defined_mount(socket) -> # if any
      assign_computed_states(socket)

  This reason we assign computed states last is because they may depend on data from params
  or session.  LiveProps does not handle params and session so you will need to manually
  assign them in your own mount callback, if needed.

  ### Example

        defmodule ThermostatLive do
          # If you generated an app with mix phx.new --live,
          # the line below would be: use MyAppWeb, :live_view
          use Phoenix.LiveView
          use LiveProps.LiveView

  '''
  import Phoenix.LiveView

  defmacro __using__(_) do
    quote do
      use LiveProps, include: [:state]

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    [
      quoted_handle_info(env),
      quoted_mount(env)
    ]
  end

  defp quoted_handle_info(_env) do
    quote do
      def handle_info({:liveprops, event, args}, socket) do
        LiveProps.LiveView.__handle_info__({event, args}, socket, __MODULE__)
      end
    end
  end

  defp quoted_mount(env) do
    if Module.defines?(env.module, {:mount, 3}) do
      quote do
        defoverridable mount: 3

        def mount(params, session, socket) do
          if connected?(socket), do: send(self(), {:liveprops, :after_connect, []})

          socket = LiveProps.__assign_states__(socket, :defaults, __MODULE__)

          {:ok, socket} = super(params, session, socket)

          socket = LiveProps.__assign_states__(socket, :computed, __MODULE__)

          {:ok, socket}
        end
      end
    else
      quote do
        def mount(params, session, socket) do
          LiveProps.LiveView.__mount__(params, session, socket, __MODULE__)
        end
      end
    end
  end

  @doc false
  def __mount__(_params, _session, socket, module) do
    if connected?(socket), do: send(self(), {:liveprops, :after_connect, []})

    {:ok,
      socket
      |> LiveProps.__assign_states__(:defaults, module)
      |> LiveProps.__assign_states__(:computed, module)}
  end

  @doc false
  def __handle_info__({event, args}, socket, module) do
    apply(__MODULE__, event, [socket, module] ++ args)
  end

  @doc false
  def after_connect(socket, module) do
    {:noreply,
      socket
      |> LiveProps.__assign_states__(:async, module)}
  end
end
