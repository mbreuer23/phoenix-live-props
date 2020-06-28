defmodule LiveProps do
  @moduledoc """
  Documentation for `LiveProps`.
  """
  require LiveProps.API

  defdelegate set_state(socket, assigns), to: LiveProps.API

  defdelegate send_state(module, id, assigns), to: LiveProps.API
end
