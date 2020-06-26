defmodule LiveProps.Validations do
  @moduledoc """
  Functions to validate options when defining props or state.

  Will raise compiler errors in case of problems
  """
  @valid_attributes [:live_prop, :live_state]

  def validate_opts!(attribute, name, type, opts, caller) do
    # raise ArgumentError, "bad args"
    with :ok <- validate_attribute(attribute),
         :ok <- validate_name(caller, attribute, name),
         :ok <- validate_type(type),
         :ok <- validate_opts(caller, attribute, opts) do
      :ok
    else
      {:error, message} ->
        file = Path.relative_to_cwd(caller.file)
        raise %CompileError{line: caller.line, file: file, description: message}
    end
  end

  defp validate_attribute(attribute) when attribute in @valid_attributes do
    :ok
  end

  defp validate_attribute(attribute) do
    {:error,
     "Attribute must be one of #{inspect(@valid_attributes)}.  Received #{inspect(attribute)}"}
  end

  defp validate_name(caller, attribute, name) when is_atom(name) do
    case name_already_defined?(caller.module, attribute, name) do
      true ->
        {:error, "Name #{name} of type #{attribute} defined more than once."}

      false ->
        :ok
    end
  end

  defp validate_name(_, name, _) do
    {:error, "Name should be an atom, received #{inspect(name)}"}
  end

  defp name_already_defined?(module, attribute, name) do
    Module.get_attribute(module, attribute, [])
    |> Enum.filter(&(&1.name == name))
    |> length()
    |> Kernel.>(0)
  end

  defp validate_type(type) when is_atom(type) do
    :ok
  end

  defp validate_type(type) do
    {:error, "Type should be an atom; receieved #{inspect(type)}"}
  end

  defp validate_opts(caller, attribute, opts) do
    valid_opts = valid_opts_for_attribute(attribute)
    required_opts = required_opts_for_attribute(attribute)

    with true <- Keyword.keyword?(opts),
         supplied_keys <- Keyword.keys(opts),
         :ok <- validate_required_opts(supplied_keys, required_opts),
         :ok <- validate_no_extra_opts(supplied_keys, valid_opts),
         :ok <- validate_each_opt(caller, attribute, opts) do
      :ok
    else
      false ->
        {:error, "Opts should be a keyword list, got #{inspect(opts)}"}

      {:error, message} ->
        {:error, message}

        # unknown ->
        #   {:error, "Invalid options: #{inspect(unknown)}"}
    end
  end

  defp valid_opts_for_attribute(:live_prop) do
    [:default, :compute, :required, :doc]
  end

  defp valid_opts_for_attribute(_attribute) do
    [:default]
  end

  defp required_opts_for_attribute(:live_state) do
    []
  end

  defp required_opts_for_attribute(:live_prop) do
    []
  end

  defp validate_required_opts(keys, required_opts) do
    case required_opts -- keys do
      [] -> :ok
      _ -> {:error, "The following options are required. #{inspect(required_opts)}"}
    end
  end

  defp validate_no_extra_opts(supplied_opts, valid_opts) do
    case supplied_opts -- valid_opts do
      [] -> :ok
      unknown -> {:error, "Invalid options: #{inspect(unknown)}"}
    end
  end

  defp validate_each_opt(caller, attribute, opts) when is_list(opts) do
    Enum.reduce(opts, :ok, fn
      {opt, value}, :ok ->
        validate_option_value(caller, attribute, opt, value)

      _opt, {:error, msg} ->
        {:error, msg}
    end)
  end

  defp validate_option_value(_caller, _, :compute, function) when is_function(function, 1) do
    :ok
    # with %{module: module, name: name, arity: arity} <- Function.info(function),
    #     true <- function_exported?(module, name, arity) do
    #       :ok
    #     else
    #       _ ->
    #       {:error, "Undefined function #{inspect(function)}"}
    #     end
  end

  defp validate_option_value(_caller, _, :compute, function) when is_atom(function) do
    :ok
    # case Module.defines?(caller.module, {function, 1}) do
    #   true ->
    #     :ok

    #   false ->
    #     {:error, "Undefined function.  #{function} should be an atom with the name of a 1-arity function"}
    # end
  end

  defp validate_option_value(_, _, :compute, function) do
    {:error, "Expected a 1-arity function or an atom.  Received #{inspect(function)}"}
  end

  defp validate_option_value(_, _, :required, value) when is_boolean(value) do
    :ok
  end

  defp validate_option_value(_, _, :required, value) do
    {:error, "Option :required should be a boolean.  Received #{inspect(value)}"}
  end

  defp validate_option_value(_, _, _, _) do
    :ok
  end
end
