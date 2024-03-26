defmodule Archive do
  alias Archive.{Post, Url}

  @spec process(String.t()) :: {:error, any()} | {:ok, charlist() | {charlist(), binary()}}
  def process(book_name) do
    book_name
    |> make_directory()
    |> parse_posts()
    |> attach_images(book_name)
    |> add_book_info(book_name)
    |> write_to_file(book_name)
    |> zip(book_name)
  end

  @spec dir() :: String.t()
  def dir do
    Application.fetch_env!(:archive, :project_root)
  end

  defp make_directory(book_name) do
    book_name
    |> working_directory()
    |> File.mkdir()

    book_name
  end

  defp working_directory(book_name) do
    Path.join([dir(), "priv", "archives", book_name])
  end

  @spec parse_posts(String.t()) :: [Post.t(), ...]
  def parse_posts(book_name) do
    "#{book_name}.txt"
    |> File.stream!()
    |> Post.parse_lines()
  end

  @spec attach_images([Post.t(), ...], String.t()) ::
          {:ok, [Post.t(), ...]} | {:error, String.t()}
  defp attach_images(posts, book_name) do
    directory = working_directory(book_name)

    posts
    |> check_posts()
    |> attach_images_as_need(directory)
  end

  @spec attach_images_as_need({:error, String.t()} | {:ok, [Post.t()]}, String.t()) ::
          {:error, String.t()} | {:ok, [Post.t(), ...]}
  defp attach_images_as_need({:ok, posts}, directory) when is_list(posts) do
    result = Archive.Image.attach_image_if_needed(posts, Url.files(), directory)
    {:ok, result}
  end

  defp attach_images_as_need({:error, message}, _), do: {:error, message}

  @spec check_posts([Post.t(), ...]) :: {:ok, [Post.t(), ...]} | {:error, String.t()}
  defp check_posts(posts) do
    image_posts = Archive.Image.posts_needing_images(posts)

    # {:ok, posts}

    if length(image_posts) == length(Url.files()) do
      {:ok, posts}
    else
      {:error, "Missing #{length(image_posts) - length(Url.files())} files"}
    end
  end

  defp add_book_info({:ok, posts}, book_name) do
    book_info = Jason.decode!(File.read!("#{book_name}.json"))
    {:ok, Map.put(book_info, :posts, posts)}
  end

  defp add_book_info({:error, message}, _), do: {:error, message}

  defp write_to_file({:ok, posts}, book_name) do
    File.write(
      Path.join(working_directory(book_name), "#{book_name}_final.json"),
      Jason.encode!(posts)
    )
  end

  defp write_to_file(other, _), do: other

  defp zip(:ok, book_name) do
    directory = working_directory(book_name)
    files = File.ls!(directory) |> Enum.map(&String.to_charlist/1)

    :zip.create(String.to_charlist(Path.join(directory, "#{book_name}.zip")), files,
      cwd: String.to_charlist(directory)
    )
  end
end
