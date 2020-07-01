# defmodule TestTest do
#   use ExUnit.Case
#   # import Plug.Conn
#   # import Phoenix.ConnTest
#   import Phoenix.LiveViewTest
#   @endpoint Endpoint

#   defmodule LiveView do
#     use Phoenix.LiveView

#     def render(assigns) do
#       ~L"""
#       <%= live_component @socket, TestTest.Component,
#         id: "id",
#         prop1: @prop1,
#         prop2: @prop2
#         %>

#       <%= live_component @socket, TestTest.Component,
#         id: "id2",
#         prop1: @prop1,
#         prop2: @prop2
#         %>
#         <button phx-click="send_update">Update</button>
#       """
#     end

#     def mount(_, _, socket) do
#       {:ok,
#        socket
#        |> assign(:prop1, true)
#        |> assign(:prop2, false)}
#     end

#     def handle_event("send_update", _, socket) do
#       send_update(TestTest.Component, id: "id", prop3: :prop3)
#       {:noreply, socket}
#     end
#   end

#   defmodule Component do
#     use Phoenix.LiveComponent

#     def render(assigns) do
#       ~L"""
#       <div>I am a component</div>
#       """
#     end

#     def update(assigns, socket) do
#       IO.inspect(assigns, label: "component update assigns")
#       socket = assign(socket, assigns)
#       IO.inspect(socket.changed, label: "socket changed")
#       {:ok, socket}
#     end

#     def preload(list) do
#       IO.inspect(list, label: "list of assigns")
#     end

#     def mount(socket) do
#       IO.inspect(socket.assigns, label: "Component mount")
#       {:ok, socket}
#     end
#   end

#   setup do
#     [conn: Phoenix.ConnTest.build_conn()]
#   end

#   test "render", %{conn: conn} do
#     {:ok, view, _} = live_isolated(conn, LiveView)

#     view
#     |> element("button")
#     |> render_click()
#   end
# end
