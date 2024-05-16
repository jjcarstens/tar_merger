defmodule TarMerger.Entry do
  @moduledoc """
  A module to read a tar file and return a list of maps containing filename,
  offset, and permissions.
  """

  defstruct path: "",
            contents: nil,
            type: :regular,
            mode: 0,
            uid: 0,
            gid: 0,
            size: 0,
            mtime: 0,
            link: "",
            major_device: 0,
            minor_device: 0

  @type t() :: %__MODULE__{
          path: String.t(),
          contents: tuple(),
          type: :device | :directory | :regular | :other | :symlink,
          mode: non_neg_integer(),
          uid: non_neg_integer(),
          gid: non_neg_integer(),
          link: String.t(),
          size: non_neg_integer(),
          mtime: String.t(),
          major_device: non_neg_integer(),
          minor_device: non_neg_integer()
        }

  def regular(path, info) do
    %__MODULE__{
      path: normalize_path(path),
      type: :regular,
      contents: Keyword.fetch!(info, :contents),
      mode: Keyword.fetch!(info, :mode) |> normalize_mode(),
      size: Keyword.fetch!(info, :size)
    }
  end

  def directory(path, info) do
    %__MODULE__{
      path: path |> normalize_path() |> normalize_dir(),
      type: :directory,
      mode: Keyword.fetch!(info, :mode) |> normalize_mode()
    }
  end

  def symlink(path, info) do
    %__MODULE__{
      path: normalize_path(path),
      type: :symlink,
      mode: Keyword.fetch!(info, :mode) |> normalize_mode(),
      link: Keyword.fetch!(info, :link),
      size: 0
    }
  end

  def device(path, info) do
    %__MODULE__{
      path: normalize_path(path),
      type: :device,
      mode: Keyword.fetch!(info, :mode) |> normalize_mode(),
      size: 0,
      major_device: Keyword.fetch!(info, :major_device),
      minor_device: Keyword.fetch!(info, :minor_device)
    }
  end

  defp normalize_mode(mode) do
    Bitwise.band(mode, 0o7777)
  end

  defp normalize_path("../" <> path),
    do: raise(RuntimeError, "Previous directory not supported in path: ../#{path}")

  defp normalize_path("./" <> path), do: "./" <> path
  defp normalize_path("/" <> path), do: "./" <> path
  defp normalize_path(path), do: "./" <> path

  defp normalize_dir(path) do
    # Tarball directories always end with /'s
    if String.ends_with?(path, "/") do
      path
    else
      path <> "/"
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{type: :regular} = entry, opts) do
      concat([
        "TarMerger.Entry.regular(",
        Inspect.inspect(entry.path, opts),
        ", contents: ",
        Inspect.inspect(entry.contents, opts),
        ", mode: ",
        Inspect.inspect(entry.mode, Map.put(opts, :base, :octal)),
        ", size: ",
        Inspect.inspect(entry.size, opts),
        ")"
      ])
    end

    def inspect(%{type: :directory} = entry, opts) do
      concat([
        "TarMerger.Entry.directory(",
        Inspect.inspect(entry.path, opts),
        ", mode: ",
        Inspect.inspect(entry.mode, Map.put(opts, :base, :octal)),
        ")"
      ])
    end

    def inspect(%{type: :symlink} = entry, opts) do
      concat([
        "TarMerger.Entry.symlink(",
        Inspect.inspect(entry.path, opts),
        ", mode: ",
        Inspect.inspect(entry.mode, Map.put(opts, :base, :octal)),
        ", link: ",
        Inspect.inspect(entry.link, opts),
        ")"
      ])
    end

    def inspect(%{type: :device} = entry, opts) do
      concat([
        "TarMerger.Entry.device(",
        Inspect.inspect(entry.path, opts),
        ", mode: ",
        Inspect.inspect(entry.mode, Map.put(opts, :base, :octal)),
        ", major_device: ",
        Inspect.inspect(entry.major_device, opts),
        ", minor_device: ",
        Inspect.inspect(entry.minor_device, opts),
        ")"
      ])
    end

    def inspect(%{type: :pax_header} = entry, opts) do
      concat([
        "TarMerger.Entry.pax_header(",
        Inspect.inspect(entry.path, opts),
        ", contents: ",
        Inspect.inspect(entry.contents, opts),
        ", mode: ",
        Inspect.inspect(entry.mode, Map.put(opts, :base, :octal)),
        ", size: ",
        Inspect.inspect(entry.size, opts),
        ")"
      ])
    end
  end
end