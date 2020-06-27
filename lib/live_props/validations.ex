defmodule LiveProps.Validations do
  @moduledoc """
  Functions to validate options when defining props or state.

  Will raise in case of problems
  """
  @valid_attributes [:prop, :state]

  def validate_opts!(attribute, name, type, opts) do
    if Keyword.keyword?(opts) == false do
      raise ArgumentError, "Options should be a keyword list.  Received #{inspect(opts)}"
    end

    validate_attribute(attribute)
    validate_name(attribute, name)
    validate_type(type)
    validate_required_opts(attribute, opts)
    validate_no_extra_opts(attribute, opts)
    validate_each_opt(attribute, opts)
  end

  defp validate_attribute(attribute) when attribute in @valid_attributes do
    :ok
  end

  defp validate_attribute(attribute) do
    raise ArgumentError,
          "Attribute must be one of #{inspect(@valid_attributes)}.  Received #{inspect(attribute)}"
  end

  defp validate_name(_attribute, name) when is_atom(name) do
    :ok
  end

  defp validate_name(name, _) do
    raise ArgumentError, "Name should be an atom, received #{inspect(name)}"
  end

  defp validate_type(type) when is_atom(type) do
    :ok
  end

  defp validate_type(type) do
    raise ArgumentError, "Type should be an atom; receieved #{inspect(type)}"
  end

  defp valid_opts_for_attribute(:prop) do
    [:default, :compute, :required, :doc]
  end

  defp valid_opts_for_attribute(:state) do
    [:default, :compute, :after_connect, :doc]
  end

  defp valid_opts_for_attribute(_) do
    []
  end

  defp required_opts_for_attribute(:state) do
    []
  end

  defp required_opts_for_attribute(:prop) do
    []
  end

  defp validate_required_opts(attribute, opts) do
    required_opts = required_opts_for_attribute(attribute)
    supplied_keys = Keyword.keys(opts)

    case required_opts -- supplied_keys do
      [] -> :ok
      _ -> raise ArgumentError, "The following options are required. #{inspect(required_opts)}"
    end
  end

  defp validate_no_extra_opts(attribute, opts) do
    supplied_opts = Keyword.keys(opts)
    valid_opts = valid_opts_for_attribute(attribute)

    case supplied_opts -- valid_opts do
      [] -> :ok
      unknown -> raise ArgumentError, "Invalid options: #{inspect(unknown)}"
    end
  end

  defp validate_each_opt(attribute, opts) when is_list(opts) do
    for {opt, value} <- opts do
      validate_opt(attribute, opt, value, opts)
    end
  end

  defp validate_opt(attribute, opt, value, opts)

  defp validate_opt(_, :compute, func, _) when is_function(func, 1), do: nil
  defp validate_opt(_, :compute, func, _) when is_atom(func), do: nil

  defp validate_opt(_, :compute, func, _) do
    raise ArgumentError, "Expected a 1-arity function or an atom.  Received #{inspect(func)}"
  end

  defp validate_opt(_, :required, value, _) when is_boolean(value), do: nil

  defp validate_opt(_, :required, value, _) do
    raise ArgumentError, "Option :required should be a boolean.  Received #{inspect(value)}"
  end

  defp validate_opt(_, :after_connect, value, opts) when is_boolean(value) do
    case opts[:compute] do
      nil ->
        raise ArgumentError, "must pass :compute option to use :after_connect"

      _ ->
        nil
    end
  end

  defp validate_opt(_, :after_connect, value, _) do
    raise ArgumentError, ":after_connect must be a boolean.  Received #{inspect(value)}"
  end

  defp validate_opt(_, _, _, _), do: nil
end
