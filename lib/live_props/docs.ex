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
    Map.take(prop, [:default, :required, :compute])
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

  defp proplist(props, heading) do
    docs =
      for prop <- props do
        doc = doc_string(prop)
        opts = opts_string(prop)
        "* **#{prop.name}** *#{inspect(prop.type)}#{opts}*#{doc}"
      end
      |> Enum.join("\n")

    if String.length(docs) > 0 do
      """
      ### #{heading}
      #{docs}
      """
    else
      ""
    end
  end

  defp generate_props_docs(module) do
   props = Module.get_attribute(module, LiveProps.API.prefix(:prop), [])
   noncomputed_props = for p <- props, p[:is_computed] != true, do: p
   computed_props = props -- noncomputed_props

   proplist(noncomputed_props, "Properties") <> proplist(computed_props, "Computed properties")
  end

  defp format_opts(opts_ast) do
    opts_ast
    |> Macro.to_string()
    |> String.slice(1..-2)
    # |> backtick_functions()
  end

  # defp backtick_functions(string) do
  #   Regex.replace(~r/&(.*)\/{}/, string, replacement, options \\ [])/
  # end

end
