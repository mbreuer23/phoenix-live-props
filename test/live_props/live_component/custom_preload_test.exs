defmodule LiveProps.LiveComponent.CustomUpdateTest do
  use LiveProps.ConnCase
  import LiveProps.CreateViews

  view Parent do
    state :items, :list, default: [1, 2, 3, 4]

    def render(assigns) do
      ~L"""
      <%= for i <- @items do %>
        <%= live_component @socket, MyComponent,
              id: i,
              undefined_prop: true,
              prop1: :parent %>
      <% end %>
      <button phx-click="update">Update</button>
      """
    end

    def handle_event("update", _, socket) do
      send_state(MyComponent, 1, [state1: :update])
      {:noreply, socket}
    end
  end

  component MyComponent do
    prop :prop1, :any, default: nil
    prop :prop2, :any, default: true
    state :state1, :any, default: "state1"

    def render(assigns) do
      ~L"""
      <div>
        <%= inspect(assigns) %>
      </div>
      """
    end

    def preload(list_of_assigns) do
      Enum.map(list_of_assigns, fn assigns ->
        Map.put(assigns, :has_props, Map.has_key?(assigns, :prop1))
      end)
    end

    def update(_assigns, socket) do
      {:ok, socket}
    end
  end

  test "renders", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, Parent)

    assert html =~ "prop1: :parent"
    assert html =~ "state1: &quot;state1&quot;"
    assert html =~ "has_props: true"

    view
    |> element("button", "Update")
    |> render_click()

    assert view |> render() =~ "state1: :update"
  end
end
