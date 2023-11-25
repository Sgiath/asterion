defmodule Asterion do
  @source "priv/sources/Siomenuv_archiv_v3.xlsx"

  @sig_place %{
    1 => "centrální_metropole",
    2 => "významné_větší",
    3 => "okrajové_sídlo",
    4 => "opuštěné_sídlo",
    "" => ""
  }

  @sig_person %{
    1 => "panovník říše, globálně významná a mocná postava",
    2 => "významný politik, představený organizace, mocná postava",
    3 => "lokální správce, zkušený dobrodruh, hlavní postava",
    4 => "obyvatel, vedlejší postava",
    5 => "okrajová zmínka",
    "" => "neznámý"
  }

  @status %{
    "*" => "naživu",
    "†" => "mrtvý/á",
    "?" => "nejisté",
    "" => "neznámý"
  }

  @power %{
    1 => "nejmocnější",
    2 => "silná",
    3 => "slabá",
    "" => "neznamá"
  }

  def load_all do
    [
      {:ok, places},
      {:ok, _explanation},
      {:ok, people},
      {:ok, organizations},
      {:ok, races},
      {:ok, fauna},
      {:ok, thought_beings},
      {:ok, artifacts},
      {:ok, _battles},
      {:ok, _dragons_and_deities}
    ] = Xlsxir.multi_extract(@source)

    Task.await_many([
      Task.async(fn -> load(places, "places", &places/1) end),
      Task.async(fn -> load(people, "people", &people/1) end),
      Task.async(fn -> load(organizations, "organizations", &organizations/1) end),
      Task.async(fn -> load(races, "races", &races/1) end),
      Task.async(fn -> load(fauna, "fauna", &fauna/1) end),
      Task.async(fn -> load(thought_beings, "thought-beings", &thought_beings/1) end),
      Task.async(fn -> load(artifacts, "artifacts", &artifacts/1) end)
    ])

    :ok
  end

  def load(data, type, parse) do
    File.mkdir_p!("priv/export/#{type}/")

    [_title, _info | parsed] = Xlsxir.get_list(data)

    parsed
    |> Enum.reject(fn [name | _rest] -> is_nil(name) end)
    |> Enum.map(fn data ->
      parsed = parse.(data)
      md_file = EEx.eval_file("priv/templates/#{type}.md.eex", parsed)

      File.write!("priv/export/#{type}/#{Keyword.get(parsed, :name)}.md", md_file)
    end)
  end

  def places([name, geo, place, ruler, description, sig, sources | _rest]) do
    {name, aliases} = format_name(name)

    [
      name: name,
      aliases: aliases,
      geo: normalize_unknown(geo),
      place: normalize_unknown(place),
      ruler: normalize_unknown(ruler),
      description: description,
      significance: @sig_place[sig],
      sources: format_sources(sources)
    ]
  end

  def people([name, sex, race, place, org, desc, status, sig, sources | _rest]) do
    {name, aliases} = format_name(name)

    [
      name: name,
      aliases: aliases,
      sex: sex,
      race: normalize_unknown(race),
      place: normalize_unknown(place),
      organization: normalize_unknown(org),
      description: desc,
      status: @status[status],
      significance: @sig_person[sig],
      sources: format_sources(sources)
    ]
  end

  def organizations([name, leadership, place, geo, expertise, desc, sources | _rest]) do
    [name | aliases1] = String.split(name, " / ")
    [name | aliases2] = String.split(name, " (")

    aliases = aliases1 ++ Enum.map(aliases2, &String.trim_trailing(&1, ")"))

    leadership =
      leadership
      |> String.split(", ")
      |> Enum.map(fn l ->
        [l | _rest] = String.split(l, " (")

        l
        |> normalize_unknown()
        |> String.replace("\"", "")
      end)
      |> Enum.reject(&(byte_size(&1) == 0))

    place =
      place
      |> String.split(", ")
      |> Enum.map(&normalize_unknown/1)
      |> Enum.reject(&(byte_size(&1) == 0))

    [
      name: name,
      aliases: aliases,
      leadership: leadership,
      place: place,
      geo: format_geo(geo),
      expertise: String.split(expertise, ", "),
      description: desc,
      sources: format_sources(sources)
    ]
  end

  def races([name, geo, kind, desc, sources | _rest]) do
    {name, aliases} = format_name(name)

    [
      name: name,
      aliases: aliases,
      geo: format_geo(geo),
      kind: kind,
      description: desc,
      sources: format_sources(sources)
    ]
  end

  def fauna([name, kind, desc, geo, sources | _unique]) do
    {name, aliases} = format_name(name)

    [
      name: name,
      aliases: aliases,
      geo: format_geo(geo),
      kind: normalize_unknown(kind),
      description: desc,
      sources: format_sources(sources)
    ]
  end

  def thought_beings([name, kind, emotion, power, sources | _unique]) do
    {name, aliases} = format_name(name)

    [
      name: name,
      aliases: aliases,
      kind: kind,
      emotion: emotion,
      power: @power[power],
      sources: format_sources(sources)
    ]
  end

  def artifacts([name, place, kind, desc, sources | _rest]) do
    {name, aliases} = format_name(name)

    [
      name: name,
      aliases: aliases,
      place: normalize_unknown(place),
      kind: kind,
      description: desc,
      sources: format_sources(sources)
    ]
  end

  defp format_name(name) do
    [name | aliases] = String.split(name, " (")
    {name, Enum.map(aliases, &String.trim_trailing(&1, ")"))}
  end

  defp format_geo(geo) do
    geo
    |> String.split(", ")
    |> Enum.map(fn g ->
      [g | _rest] = String.split(g, " (")
      g
      |> normalize_unknown()
      |> String.trim_trailing(" a okolí")
      # |> String.trim_leading("okolí ")
    end)
    |> Enum.map(fn
      "Lendor a Tara" -> ["Lendor", "Tara"]
      "okolí Athoru" -> "Athor"
      "okrajově i sousedé" -> []
      other -> other
    end)
    |> List.flatten()
    |> Enum.reject(&(byte_size(&1) == 0))
  end

  defp format_sources(sources) when is_binary(sources) do
    sources
    |> String.split(";")
    |> format_sources()
  end

  defp format_sources(sources) when is_list(sources) do
    sources
    |> Enum.map(&String.trim/1)
    |> Enum.map(&format_source/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn
      {s, nil} -> s
      {s, p} -> "#{s} #{p}"
    end)
  end

  defp normalize_unknown("?"), do: ""
  defp normalize_unknown("x"), do: ""
  defp normalize_unknown("nezávislý"), do: ""
  defp normalize_unknown("klan"), do: ""
  defp normalize_unknown("nestálá"), do: ""
  defp normalize_unknown("rozné"), do: ""
  defp normalize_unknown("větší města"), do: ""
  defp normalize_unknown("na cestách"), do: ""
  defp normalize_unknown("dříve " <> _any), do: ""
  defp normalize_unknown(known), do: known

  defp format_source("DD " <> pages), do: {"Dech Draka", pages}
  defp format_source("P " <> pages), do: {"Pevnost", pages}
  defp format_source("web " <> pages), do: {"web", pages}
  defp format_source("Pat " <> pages), do: {"Petreon", pages}
  defp format_source("HM " <> pages), do: {"Hlavní modul", pages}
  defp format_source("D " <> pages), do: {"Dálavy", pages}
  defp format_source("ČT " <> pages), do: {"Čas temna", pages}
  defp format_source("NS " <> pages), do: {"Nemrtví a světlonoši", pages}
  defp format_source("PP " <> pages), do: {"Písky proroctví", pages}
  defp format_source("VTB " <> pages), do: {"Vzestup temných bohů", pages}
  defp format_source("ZHZM " <> pages), do: {"Z hlubin zelené a modré", pages}
  defp format_source("ZP " <> pages), do: {"Zlatá pavučina", pages}
  defp format_source("OLD " <> pages), do: {"Obloha z listí a drahokamů", pages}
  defp format_source("FA " <> pages), do: {"Falešná apokalypsa", pages}
  defp format_source("ZZS " <> pages), do: {"Za závojem stínů", pages}
  defp format_source("RD " <> pages), do: {"Rukověť dobrodruha", pages}
  defp format_source("SJ " <> pages), do: {"Krajiny za obzorem: Stíny jihu", pages}
  defp format_source("PSS " <> pages), do: {"Pro smrt a slávu", pages}
  defp format_source("SŽ " <> pages), do: {"Sedmý živel", pages}

  defp format_source("SVV " <> pages),
    do: {"Krajiny za obzorem: Sarindarské výsostné vody", pages}

  defp format_source("Kaat " <> pages), do: {"Kaat aneb historky Cechu Eldebranských katů", pages}
  defp format_source("ZMM " <> pages), do: {"Zrození Modrého měsíce", pages}

  defp format_source("Smrťáček " <> pages),
    do: {"Krumpáč a motyky: Smrťáček aneb Cesta za smrtí a zase zpátky", pages}

  defp format_source("MP " <> pages), do: {"Město přízraků", pages}
  defp format_source("CS"), do: {"Cesty snů", nil}
  defp format_source("ZM " <> pages), do: {"Zpívající meč: Čajový drak a kočičí démon", pages}
  defp format_source("ŠVZ"), do: {"Stíny Erinu: Šíp v zádech", nil}
  defp format_source("HH " <> pages), do: {"Krumpáč a motyky: Hrobnické historky", pages}
  defp format_source("PZ"), do: {"Pevnost zoufalství", nil}
  defp format_source("Marellion " <> pages), do: {"Marellion", pages}
  defp format_source("Louskáček " <> pages), do: {"Louskáček", pages}
  defp format_source("VVP " <> pages), do: {"Vločka v plamenech", pages}
  defp format_source("ÚNB " <> pages), do: {"Úsvit nových bohů", pages}
  defp format_source("ZT " <> pages), do: {"Hry s příběhem 1: Zločin a trest", pages}
  defp format_source("OK " <> pages), do: {"Hry s příběhem 2: Ocel a krev", pages}
  defp format_source("VD " <> pages), do: {"Hry s příběhem 3: Volání divočiny", pages}

  defp format_source("Temné časy " <> pages),
    do: {"mimoasterionský sborník povídek temné fantasy", pages}

  defp format_source(""), do: nil

  defp format_source(source) do
    [source | pages] = String.split(source, " ")
    {source, Enum.join(pages, " ")}
  end
end
