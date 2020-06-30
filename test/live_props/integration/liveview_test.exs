defmodule LiveProps.IntegrationTest.LiveView do
  use ExUnit.Case
  # import Plug.Conn
  # import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint Endpoint

  defmodule Parent do
    use Phoenix.LiveView
    use LiveProps.LiveView
    alias LiveProps.IntegrationTest.LiveView.Child1

    state :user_id, :integer, default: 1
    state :show_comments, :boolean, default: false

    def render(assigns) do
      ~L"""
      Welcome user <%= @user_id %>

      <button phx-click="toggle" id="toggle">Show Comments</button>
      <button phx-click="update", id="update">Update comments</button>

      <%= live_component @socket, Child1,
        id: "child1",
        user_id: @user_id,
        show_comments: @show_comments %>
      """
    end

    def handle_event("toggle", _, socket) do
      {:noreply, set_state(socket, :show_comments, !socket.assigns.show_comments)}
    end

    def handle_event("update", _, socket) do
      send_state(Child1, "child1", comments: [:updated_comments])
      {:noreply, socket}
    end
  end

  defmodule Child1 do
    use Phoenix.LiveComponent
    use LiveProps.LiveComponent

    prop :user_id, :integer, default: nil
    prop :show_comments, :boolean, default: true
    prop :has_user_id, :boolean, compute: :has_user_id

    state :comments, :list, default: [:comment1, :comment2]
    state :comment_count, :count, compute: :get_count

    def render(assigns) do
      ~L"""
      <div>
        <%= if @show_comments do %>
          <div>List comments (count: <%= @comment_count %>)</div>
          <%= for c <- @comments do %>
            <%= inspect(c) %>
          <% end %>
        <% end %>
        <button id="set-state" phx-target="<%= @myself %>" phx-click="set-state">Set comments</button>
      </div>
      """
    end

    def handle_event("set-state", _, socket) do
      {:noreply, set_state(socket, %{comments: [1, 2, 3, 4]})}
    end

    def get_count(assigns) do
      length(assigns[:comments])
    end

    def has_user_id(assigns) do
      Map.has_key?(assigns, :user_id)
    end
  end

  setup do
    [conn: Phoenix.ConnTest.build_conn()]
  end

  test "works", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, Parent)
    assert html =~ "Welcome user 1"
    refute html =~ "List comments"

    # changing props are reflected in component
    html =
      view
      |> element("#toggle")
      |> render_click()

    assert html =~ "List comments"
    assert html =~ ":comment1"
    assert html =~ "count: 2"

    # changing Child state from Parent
    view
    |> element("#update")
    |> render_click()

    html = view |> render()
    assert html =~ ":updated_comments"
    assert html =~ "count: 1"

    # changing Child state within Child
    html =
      view
      |> element("#set-state")
      |> render_click()

    assert html =~ "count: 4"
  end
end
