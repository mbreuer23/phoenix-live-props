defmodule LiveProps.Factory do
  @moduledoc """
  Functions to validate and build representations of props and state.

  """
  alias LiveProps.Validations

  @spec build_attribute!(
          attribute :: :prop | :state,
          module :: module(),
          name :: atom(),
          type :: atom(),
          opts :: list()
        ) :: map()

  @doc """
  Validates and builds a prop or state definition.

  Returns a map.  Raises on validation errors.
  """
  def build_attribute!(attribute, name, type, opts, module) do
    Validations.validate_opts!(attribute, name, type, opts)

    inputs = merge_inputs(name, type, opts, module)

    attribute
    |> get_computed_keys()
    |> compute_keys(attribute, inputs)
    |> maybe_capture_compute_function()
  end

  defp merge_inputs(name, type, opts, module) do
    Enum.into(opts, %{name: name, type: type, module: module})
  end

  defp compute_keys(keys, attribute, inputs) do
    Enum.reduce(keys, inputs, fn key, inputs ->
      Map.put(inputs, key, build_key(attribute, key, inputs))
    end)
  end

  defp maybe_capture_compute_function(%{compute: compute} = map) when is_atom(compute) do
    Map.put(map, :compute, Function.capture(map.module, compute, 1))
  end

  defp maybe_capture_compute_function(map) do
    map
  end

  # defp make_struct!(map, :live_prop) do
  #   struct!(LiveProps.Prop, map)
  # end

  defp get_computed_keys(:prop) do
    [:has_default, :is_computed]
  end

  defp get_computed_keys(:state) do
    [:has_default, :is_computed]
  end

  defp get_computed_keys(_), do: []

  defp build_key(_, :has_default, opts) when is_map_key(opts, :default) do
    true
  end

  defp build_key(_, :has_default, _), do: false

  defp build_key(_, :is_computed, %{compute: _compute}) do
    true
  end

  defp build_key(_, :is_computed, _), do: false
end
