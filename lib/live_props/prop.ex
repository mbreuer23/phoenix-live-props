defmodule LiveProps.Prop do
  use Ecto.Schema

  import Ecto.Changeset

  alias LiveProps.Ecto.Atom

  embedded_schema do
    field :module, Atom
    field :name, Atom
    field :type, Atom
    field :default, :any, virtual: true
    field :compute, :any, virtual: true
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:update)
  end

  def changeset(base, attrs) do
    base
    |> cast(attrs, [:module, :name, :type, :default, :compute])
    |> validate_required([:module, :name, :type])
    |> validate_is_function([:compute])
  end

  defp validate_is_function(changeset, keys) when is_list(keys) do
    Enum.reduce(keys, changeset, fn key, changeset ->
      validate_is_function(changeset, key)
    end)
  end

  defp validate_is_function(changeset, key) do
    # with {:ok, value} <- fetch_change(changeset, key),
    #       true <- is_function(key)
    case fetch_change(changeset, key) do
      {:ok, _value} ->
        changeset
      :error ->
        changeset
    end
  end
end
