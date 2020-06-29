defmodule LiveProps.API.Docs do
  @moduledoc false

  def generate_docs(env) do
    props_doc = generate_props_docs(env.module)

    {line, doc} =
      case Module.get_attribute(env.module, :moduledoc) do
        nil ->
          {env.line, props_doc}

        {line, doc} ->
          {line, doc <> "\n" <> props_doc}
      end

    Module.put_attribute(env.module, :moduledoc, {line, doc})
  end

  defp get_opts(prop) do
    Map.drop(prop, [:name, :type, :module, :is_computed, :has_default])
    |> Enum.into([])
  end

  defp doc_string(prop) do
    case prop[:doc] do
      nil ->
        ""
      doc ->
        " - #{doc}."
    end
  end

  defp opts_string(prop) do
    ", #{format_opts(get_opts(prop))}"
  end

  defp generate_props_docs(module) do
    docs =
      for prop <- Module.get_attribute(module, LiveProps.API.prefix(:prop), []) do
        doc = doc_string(prop)
        opts = opts_string(prop)
        "* **#{prop.name}** *#{inspect(prop.type)}#{opts}*#{doc}"
      end
      |> Enum.reverse()
      |> Enum.join("\n")

    if String.length(docs) > 0 do
      """
      ### Properties
      #{docs}
      """
    else
      ""
    end
  end

  defp format_opts(opts_ast) do
    opts_ast
    |> Macro.to_string()
    |> String.slice(1..-2)
  end

end
