defmodule Archive.PostTest do
  use ExUnit.Case
  doctest Archive.Post

  test "parse_lines" do
    expected = [
      %{user: "gellaho", text: "line 1\nline 2", image: ""},
      %{user: "user1", text: "line 3\nline 3.5"},
      %{user: "gellaho", text: "line 4", image: ""},
      %{user: "gellaho", text: "", image: ""},
      %{user: "gellaho", text: "", image: ""},
      %{user: "gellaho", text: "", image: ""},
      %{user: "user3", text: "line 5"},
      %{user: "gellaho", text: "line 6"},
      %{user: "\"stupid 'name'\"", text: "dumber 'text' \"man\""}
    ]

    actual =
      Path.join([File.cwd!, "test", "files", "test_file.txt"])
      |> File.stream!()
      |> Archive.Post.parse_lines()

    assert(actual == expected)
  end
end
