defmodule LiveProps.LiveView do
  @moduledoc """
  Use this module inside a Phoenix.LiveView to add state management functionality to your
  liveviews
  """
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
