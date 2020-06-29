defmodule LiveProps.LiveView do
  import Phoenix.LiveView

  alias LiveProps.API

  defmacro __using__(_) do
    quote do
      use LiveProps.API, include: [:state]

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
          {:ok, socket} = LiveProps.LiveView.__mount__(params, session, socket, __MODULE__)

          super(params, session, socket)
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

  @doc """
  Assigns states with default or computed values defined in the given
  module to the socket to the
  socket and returns `{:ok, socket}`.

  All states with default or computed values (i.e. those defined with
  the `:default` or `:compute` options, respectively) will be assigned
  on mount, except computed values defined with `after_connect: true`.
  Those will be computed and assigned in a pre-defined
  `c:Phoenix.LiveView.handle_info/2` callback that
  will get invoked asynchronously after the socket
  is connected.
  """
  def __mount__(_params, _session, socket, module) do
    if connected?(socket), do: send(self(), {:liveprops, :after_connect, []})

    {:ok,
      socket
      |> API.__assign_states__(:defaults, module)
      |> API.__assign_states__(:computed, module)}
  end

  def __handle_info__({event, args}, socket, module) do
    apply(__MODULE__, event, [socket, module] ++ args)
  end

  @doc """
  Assigns any states defined with `after_connect: true` in the given
  module to the socket.

  Returns `{:noreply, socket}`
  """
  def after_connect(socket, module) do
    {:noreply,
      socket
      |> API.__assign_states__(:async, module)}
  end
end
