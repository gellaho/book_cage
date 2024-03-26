defmodule Archive.Post do
  alias Archive.Post

  @date_regex ~r/\s—\s\d{2}\/\d{2}\/\d{4}/

  @derive Jason.Encoder
  @enforce_keys [:user, :text]
  defstruct user: nil, text: nil, image: nil

  @type t :: %__MODULE__{user: String.t(), text: String.t(), image: String.t() | nil}
  @type acc :: %{user: String.t(), lines: [String.t(), ...]} | :new

  @spec parse_lines(%File.Stream{}) :: [t(), ...]
  def parse_lines(enum) do
    enum
    |> Stream.map(&clean_up/1)
    |> Stream.chunk_while(:new, &parse_line/2, &last_line/1)
    |> Stream.reject(fn x -> x == :empty end)
    |> Enum.into([])
  end

  defp clean_up(line) do
    line
    |> String.trim()
    |> String.replace(["“", "”"], "\"")
    |> String.replace(["‘", "’"], "'")
  end

  @spec parse_line(String.t(), acc) :: {:cont, t(), acc} | {:cont, acc}
  defp parse_line(line, :new) do
    {:cont, %{user: parse_user(line), lines: []}}
  end

  defp parse_line("GIF", acc) do
    {:cont, acc}
  end

  defp parse_line("Image", %{user: user, lines: lines}) do
    {:cont, %Post{user: user, text: join_lines(lines), image: ""}, %{user: user, lines: []}}
  end

  defp parse_line(new_line, acc = %{user: user, lines: lines}) do
    if String.match?(new_line, @date_regex) do
      {:cont, post_to_emit(acc), %{user: parse_user(new_line), lines: []}}
    else
      {:cont, %{user: user, lines: [new_line | lines]}}
    end
  end

  @spec post_to_emit(acc) :: t() | :empty
  defp post_to_emit(%{user: user, lines: lines}) when user == nil or length(lines) == 0,
    do: :empty

  defp post_to_emit(%{user: user, lines: lines}), do: %Post{user: user, text: join_lines(lines)}

  @spec parse_user(String.t()) :: String.t()
  defp parse_user(line) do
    ~r/(?<user>.*)\s—\s\d{2}\/\d{2}\/\d{4}/
    |> Regex.named_captures(line)
    |> Map.get("user")
  end

  @spec join_lines([String.t(), ...]) :: String.t()
  defp join_lines(lines) do
    lines
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  @spec last_line(acc) :: {:cont, t | :empty, acc}
  defp last_line(acc) do
    {:cont, post_to_emit(acc), acc}
  end
end
