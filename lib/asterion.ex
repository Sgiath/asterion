defmodule Asterion do
  @source "priv/sources/archive.xlsx"

  @sig_place %{
    1 => "centrální metropole",
    2 => "významné větší město",
    3 => "okrajové sídlo, stavba",
    4 => "opuštěné sídlo, ruina",
    "" => "neznámý"
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
      sources: String.split(sources, ";")
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
      sources: String.split(sources, ";")
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
      sources: String.split(sources, ";")
    ]
  end

  def races([name, geo, kind, desc, sources | _rest]) do
    [
      name: name,
      geo: geo,
      kind: kind,
      description: desc,
      sources: String.split(sources, ";")
    ]
  end

  def fauna([name, kind, desc, geo, sources | _unique]) do
    [
      name: name,
      geo: geo,
      kind: kind,
      description: desc,
      sources: String.split(sources, ";")
    ]
  end

  def thought_beings([name, kind, emotion, power, sources | _unique]) do
    [
      name: name,
      kind: kind,
      emotion: emotion,
      power: @power[power],
      sources: String.split(sources, ";")
    ]
  end

  def artifacts([name, place, kind, desc, sources | _rest]) do
    [
      name: name,
      place: place,
      kind: kind,
      description: desc,
      sources: String.split(sources, ";")
    ]
  end
end
