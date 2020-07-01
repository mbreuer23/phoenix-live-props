defmodule LiveProps.LiveViewTest do
  use LiveProps.ConnCase

  defmodule Examples do
    defmodule LiveViewNoMount do
      use Phoenix.LiveView
      use LiveProps.LiveView

      state :user_id, :integer, default: 1
      state :sort, :atom, default: :asc
      state :temperature, :float, compute: :get_temp
      state :async_value, :atom, default: "not loaded", compute: :get_async, after_connect: true

      def render(assigns) do
        ~L"""
        <%= if has_expected_values(assigns) do %>
          All assigns available
        <% end %>
        <%= @async_value %>
        """
      end

      defp has_expected_values(assigns) do
        assigns.user_id == 1 && assigns.sort == :asc && assigns.temperature == "temperature-1"
      end

      def get_async(_assigns) do
        "has been loaded"
      end

      def get_temp(assigns) do
        "temperature-#{inspect(assigns.user_id)}"
      end
    end

    defmodule LiveViewWithMount do
      use Phoenix.LiveView
      use LiveProps.LiveView

      state :user_id, :integer
      state :temperature, :float, compute: :get_temperature
      state :async_value, :string, default: "loading", compute: :get_async, after_connect: true

      def render(assigns) do
        ~L"""
        <%= message(assigns) %>
        <%= @async_value %>
        """
      end

      def mount(_, _, socket) do
        {:ok, assign(socket, :user_id, 1)}
      end

      def get_async(_) do
        "loaded"
      end

      defp message(assigns) do
        if assigns.user_id == 1 && assigns.temperature == "temperature-1" do
          "expected assigns available"
        else
          "missing assigns"
        end
      end

      def get_temperature(assigns) do
        "temperature-#{inspect(assigns.user_id)}"
      end
    end

    defmodule LiveViewWithMountAndOptions do
      use Phoenix.LiveView
      use LiveProps.LiveView

      state :items, :list, compute: :get_init_items

      def render(assigns) do
        ~L"""
        <div id="list" phx-update="append">
          <%= for item <- @items do %>
            <div id="<%= item.id %>">value <%= item.value %></div>
          <% end %>
        </div>
        <button phx-click="update">Update</button>
        """
      end

      def mount(_, _, socket) do
        {:ok, socket, temporary_assigns: [items: []]}
      end

      def handle_event("update", _, socket) do
        {:noreply, assign(socket, :items, get_new_items(socket))}
      end

      def get_init_items(_) do
        1..5
        |> Enum.map(&(%{id: &1, value: &1}))
      end

      def get_new_items(_) do
        6..10
        |> Enum.map(&(%{id: &1, value: &1}))
      end
    end
  end

  test "LiveView with no mount renders", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, Examples.LiveViewNoMount)

    # default and computed states available
    assert html =~ "All assigns available"

    # after_connect states available on next render
    assert html =~ "not loaded"
    assert view |> render() =~ "has been loaded"
  end

  test "Works with user mount that returns {:ok, socket}", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, Examples.LiveViewWithMount)
    assert html =~ "expected assigns available"
    assert html =~ "loading"

    assert view |> render() =~ "loaded"
  end

  test "works with user mount that returns {:ok, socket, options}", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, Examples.LiveViewWithMountAndOptions)

    Enum.each(1..5, fn i -> assert html =~ "value #{i}" end)

    html =
      view
      |> element("button", "Update")
      |> render_click()

    Enum.each(1..10, fn i -> assert html =~ "value #{i}" end)
  end

  test "LiveView does not exposes prop/3" do
    assert_raise CompileError, ~r/undefined function prop\/3/, fn ->
      defmodule Error do
        use Phoenix.LiveView
        use LiveProps.LiveView

        prop :prop1, :string, default: "prop1"
      end
    end
  end
end
