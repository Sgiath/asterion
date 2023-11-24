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
    [
      name: name,
      geo: geo,
      place: place,
      ruler: ruler,
      description: description,
      significance: @sig_place[sig],
      sources: format_sources(sources)
    ]
  end

  def people([name, sex, race, place, org, desc, status, sig, sources | _rest]) do
    [
      name: name,
      sex: sex,
      race: race,
      place: place,
      organization: org,
      description: desc,
      status: @status[status],
      significance: @sig_person[sig],
      sources: format_sources(sources)
    ]
  end

  def organizations([name, leadership, place, geo, expertise, desc, sources | _rest]) do
    [name | aliases] = String.split(name, " / ")

    [
      name: name,
      aliases: aliases,
      leadership: leadership,
      place: place,
      geo: geo,
      expertise: String.split(expertise, ", "),
      description: desc,
      sources: format_sources(sources)
    ]
  end

  def races([name, geo, kind, desc, sources | _rest]) do
    [
      name: name,
      geo: geo,
      kind: kind,
      description: desc,
      sources: format_sources(sources)
    ]
  end

  def fauna([name, kind, desc, geo, sources | _unique]) do
    [
      name: name,
      geo: geo,
      kind: kind,
      description: desc,
      sources: format_sources(sources)
    ]
  end

  def thought_beings([name, kind, emotion, power, sources | _unique]) do
    [
      name: name,
      kind: kind,
      emotion: emotion,
      power: @power[power],
      sources: format_sources(sources)
    ]
  end

  def artifacts([name, place, kind, desc, sources | _rest]) do
    [
      name: name,
      place: place,
      kind: kind,
      description: desc,
      sources: format_sources(sources)
    ]
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
    |> Enum.map(fn {s, p} -> "#{s} #{p}" end)
  end

  defp format_source("DD " <> pages), do: {"Dech Draka", pages}
  defp format_source("P " <> pages), do: {"Pevnost", pages}
  defp format_source("web " <> pages), do: {"web", pages}
  defp format_source("Pat " <> pages), do: {"Petreon", pages}
  defp format_source("HM " <> pages), do: {"Hlavní modul", pages}
  defp format_source("D " <> pages), do: {"Dálavy", pages}
  defp format_source("ČT  " <> pages), do: {"Čas temna", pages}
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
  defp format_source("SVV " <> pages), do: {"Krajiny za obzorem: Sarindarské výsostné vody", pages}
  defp format_source("Kaat " <> pages), do: {"Kaat aneb historky Cechu Eldebranských katů", pages}
  defp format_source("ZMM " <> pages), do: {"Zrození Modrého měsíce", pages}
  defp format_source("Smrťáček " <> pages), do: {"Krumpáč a motyky: Smrťáček aneb Cesta za smrtí a zase zpátky", pages}
  defp format_source("MP " <> pages), do: {"Město přízraků", pages}
  defp format_source("CS " <> pages), do: {"Cesty snů", pages}
  defp format_source("ZM " <> pages), do: {"Zpívající meč: Čajový drak a kočičí démon", pages}
  defp format_source("ŠVZ " <> pages), do: {"Stíny Erinu: Šíp v zádech", pages}
  defp format_source("HH " <> pages), do: {"Krumpáč a motyky: Hrobnické historky", pages}
  defp format_source("PZ " <> pages), do: {"Pevnost zoufalství", pages}
  defp format_source("Marellion " <> pages), do: {"Marellion", pages}
  defp format_source("Louskáček " <> pages), do: {"Louskáček", pages}
  defp format_source("VVP " <> pages), do: {"Vločka v plamenech", pages}
  defp format_source("ÚNB " <> pages), do: {"Úsvit nových bohů", pages}
  defp format_source("ZT " <> pages), do: {"Hry s příběhem 1: Zločin a trest", pages}
  defp format_source("OK " <> pages), do: {"Hry s příběhem 2: Ocel a krev", pages}
  defp format_source("VD " <> pages), do: {"Hry s příběhem 3: Volání divočiny", pages}
  defp format_source("Temné časy " <> pages), do: {"mimoasterionský sborník povídek temné fantasy", pages}
  defp format_source(""), do: nil
  defp format_source(source) do
    [source | pages] = String.split(source, " ")
    {source, Enum.join(pages, " ")}
  end
end
