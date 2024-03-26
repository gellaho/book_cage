defmodule Archive.Image do
  alias Archive.Post

  @spec posts_needing_images([Post.t(), ...]) :: [Post.t(), ...]
  def posts_needing_images(json) do
    json
    |> Enum.filter(&post_needs_image/1)
  end

  @spec post_needs_image(Post.t()) :: boolean()
  def post_needs_image(%Post{image: ""}), do: true
  def post_needs_image(%Post{}), do: false

  @spec attach_image_if_needed([Post.t()], [String.t()], String.t()) :: [Post.t(), ...]
  def attach_image_if_needed(posts, urls, directory), do: attach_image_if_needed(posts, urls, directory, [])

  @spec attach_image_if_needed([Post.t()], [String.t()], String.t(), [Post.t()]) :: [Post.t(), ...]
  defp attach_image_if_needed([], _, _, acc) do
    acc
    |> Enum.reverse()
  end

  defp attach_image_if_needed(
         [post = %Post{image: ""} | rest_posts],
         [image_url_file | rest_image_urls],
         directory,
         acc
       ) do
    image_file_name = String.replace_trailing(Path.basename(image_url_file), ".url", "")

    unless File.exists?(String.replace_trailing(image_url_file, ".url", "")) do
      url = Archive.Url.image_url(image_url_file)

      File.write!(
        Path.join(directory, image_file_name),
        Req.get!(url).body
      )
    end

    new_post = Map.replace!(post, :image, image_file_name)

    attach_image_if_needed(rest_posts, rest_image_urls, directory, [new_post | acc])
  end

  defp attach_image_if_needed([post | rest_posts], image_urls, directory, acc) do
    attach_image_if_needed(rest_posts, image_urls, directory, [post | acc])
  end
end
