defmodule LiveProps.Ecto.Atom do
    @moduledoc """
    Custom Type to support `:atom`
    defmodule Post do
      use Ecto.Schema
      schema "posts" do
        field :atom_field, Ecto.Atom
      end
    end
    """

  @behaviour Ecto.Type

  def type, do: :string

  def cast(value) when is_atom(value), do: {:ok, value}
  def cast(_), do: {:error, message: "must be an atom"}

  def load(value), do: {:ok, String.to_existing_atom(value)}

  def dump(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def dump(_), do: :error

  def embed_as(_), do: :self

  def equal?(value1, value2), do: value1 == value2
end



