defmodule LiveProps.LiveViewTest do
  use ExUnit.Case

  describe "LiveView" do
    alias Phoenix.LiveView.Socket

    defmodule Example do
      use Phoenix.LiveView
      use LiveProps.LiveView

      state :ready, :boolean, default: true
      state :posts, :list, compute: :get_posts
      state :async_posts, :list, compute: :get_posts, after_connect: true

      def render(assigns) do
        ~L"""
        <%= @ready %>
        """
      end

      def mount(_, _, socket) do
        defaults_available = socket.assigns[:ready]
        {:ok, assign(socket, :defaults_available, defaults_available)}
      end

      def get_posts(%{assigns: assigns}) do
        case assigns.ready do
          true -> [:post1, :post2]
          false -> []
        end
      end
    end

    test "mounts properly" do
      {:ok, socket} = Example.mount(%{}, %{}, %Socket{connected?: false})
      assert socket.assigns.ready == true
      assert socket.assigns.posts == [:post1, :post2]
      refute Map.has_key?(socket.assigns, :async_count)
    end

    test "sends message on connect and asynchronously computes appropriate states" do
      {:ok, socket} = Example.mount(%{}, %{}, %Socket{connected?: true})
      assert_received {:liveprops, :after_connect, []}
      refute socket.assigns[:async_posts] == [:post1, :post2]

      {:noreply, socket} = Example.handle_info({:liveprops, :after_connect, []}, socket)
      assert socket.assigns.async_posts == [:post1, :post2]
    end

    test "respects user-defined mount" do
      {:ok, socket} = Example.mount(%{}, %{}, %Socket{})
      assert socket.assigns[:defaults_available] == true
    end

    test "does not exposes prop/3" do
      assert_raise CompileError, ~r/undefined function prop\/3/, fn ->
        defmodule Error do
          use Phoenix.LiveView
          use LiveProps.LiveView

          prop :prop1, :string, default: "prop1"
        end
      end
    end
  end
end
