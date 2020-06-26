defmodule LiveProps.Factory do
  @moduledoc """
  Functions to build objects to be used as module attributes
  """
  alias LiveProps.Validations

  @spec build_attribute(
          attribute :: atom(),
          module :: module(),
          name :: atom(),
          type :: atom(),
          opts :: list()
        ) :: map()

  def build_attribute(attribute, caller, name, type, opts \\ []) do
    Validations.validate_opts!(attribute, name, type, opts, caller)

    inputs = merge_inputs(caller, name, type, opts)

    attribute
    |> get_computed_keys()
    |> compute_keys(attribute, inputs)
    |> maybe_capture_compute_function()
  end

  @spec merge_inputs(caller :: Macro.Env.t(), name :: atom(), type :: atom(), opts :: list()) ::
          map()
  defp merge_inputs(caller, name, type, opts) do
    Enum.into(opts, %{name: name, type: type, module: caller.module})
  end

  defp compute_keys(keys, attribute, inputs) do
    Enum.reduce(keys, inputs, fn key, inputs ->
      Map.put(inputs, key, build_key(attribute, key, inputs))
    end)
  end

  defp maybe_capture_compute_function(%{default: default} = map) when is_function(default) do
    # IO.inspect(Function.info(default), label: "function info")
    map
  end

  defp maybe_capture_compute_function(map) do
    map
  end

  defp make_struct!(map, :live_prop) do
    struct!(LiveProps.Prop, map)
  end

  defp get_computed_keys(:live_prop) do
    [:has_default, :is_computed]
  end

  defp get_computed_keys(_), do: []

  defp build_key(_, :has_default, opts) when is_map_key(opts, :default) do
    true
  end

  defp build_key(_, :has_default, _), do: false

  defp build_key(:live_prop, :is_computed, %{compute: _compute}) do
    true
  end

  defp build_key(:live_prop, :is_computed, _), do: false
end
