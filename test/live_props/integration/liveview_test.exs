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
    alias LiveProps.IntegrationTest.LiveView.ChildWithPreloads

    state :user_id, :integer, default: 1
    state :show_comments, :boolean, default: false

    def render(assigns) do
      ~L"""
      Welcome user <%= @user_id %>

      <button phx-click="toggle" id="toggle">Show Comments</button>
      <button phx-click="update", id="update">Update comments</button>
      <button phx-click="update2", id="update2">Update child2</button>
      <%= live_component @socket, Child1,
        id: "child1",
        user_id: @user_id,
        show_comments: @show_comments %>

      <%= live_component @socket, ChildWithPreloads,
        id: "child2",
        child_prop: :a_property %>
      """
    end

    def handle_event("toggle", _, socket) do
      {:noreply, set_state(socket, :show_comments, !socket.assigns.show_comments)}
    end

    def handle_event("update", _, socket) do
      send_state(Child1, "child1", comments: [:updated_comments])
      {:noreply, socket}
    end

    def handle_event("update2", _, socket) do
      send_state(ChildWithPreloads, "child2", some_state: "Child2 updated from parent")
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
    state :crashed, :any, default: nil
    def render(assigns) do
      ~L"""
      <div>
        <%= if @show_comments do %>
          <div>List comments (count: <%= @comment_count %>)</div>
          <%= for c <- @comments do %>
            <%= inspect(c) %>
          <% end %>
        <% end %>
        <%= if @crashed do %>
            <%= @message %>
        <% end %>
        <button id="set-state" phx-target="<%= @myself %>" phx-click="set-state">Set comments</button>
        <button id="set-bad-state" phx-target="<%= @myself %>" phx-click="set-bad-state">Set bad state</button>
      </div>
      """
    end

    def handle_event("set-state", _, socket) do
      {:noreply, set_state(socket, %{comments: [1, 2, 3, 4]})}
    end

    def handle_event("set-bad-state", _, socket) do
        try do
          {:noreply, set_state!(socket, %{not_a_state: true})}
        rescue
          e ->
            {:noreply,
              socket
              |> assign(:crashed, true)
              |> assign(:message, Exception.message(e))}
        end
    end

    def get_count(assigns) do
      length(assigns[:comments])
    end

    def has_user_id(assigns) do
      Map.has_key?(assigns, :user_id)
    end
  end

  defmodule ChildWithPreloads do
    use Phoenix.LiveComponent
    use LiveProps.LiveComponent

    prop :child_prop, :any
    prop :computed_prop, :any, default: nil, compute: :do_compute
    prop :preload, :string

    state :some_state, :string, default: "some state"

    def render(assigns) do
      ~L"""
      <div>
        <%= @preload %>
        <%= @some_state %>
      </div>
      """
    end

    def preload(list_of_assigns) do
      Enum.map(list_of_assigns, fn assigns ->
        Map.put(assigns, :preload, "i've been preloaded")
      end)
    end

    def do_compute(assigns) do
      assigns.child_prop
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

    # changing Child2 state with preload hooks
    view
    |> element("#update2")
    |> render_click()

    html = view |> render()
    assert html =~ "preloaded"
    assert html =~ "Child2 updated from parent"
  end

  test "setting invalid state", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, Parent)

    assert view
    |> element("#set-bad-state")
    |> render_click() =~ "not valid state"
  end
end
