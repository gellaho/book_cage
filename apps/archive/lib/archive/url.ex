defmodule Archive.Url do
  @url_files "priv/urls/**.url"

  @spec files() :: [String.t()]
  def files do
    Archive.dir()
    |> Path.join(@url_files)
    |> Path.wildcard()
    |> Enum.sort_by(fn file -> File.stat!(file, time: :posix).mtime end)
  end

  def image_url(url_file) do
    file = File.read!(url_file)

    ~r/URL=(?<url>.+)\r\n/
    |> Regex.named_captures(file)
    |> Map.get("url")
  end
end
