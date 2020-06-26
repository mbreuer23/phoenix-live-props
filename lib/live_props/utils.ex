defmodule LiveProps.Utils do
  def get_attributes_in_order_defined(module, attribute) do
    Module.get_attribute(module, attribute, []) |> Enum.reverse()
  end

  def get_attributes_with_key(attribute_list, key) do
    for attr <- attribute_list, Map.has_key?(attr, key), do: attr
  end
end
