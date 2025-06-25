defmodule StackoverflowClone.StackOverflow.RecentSearches do
  @moduledoc """
  Handles recent search persistence and retrieval
  """

  alias StackoverflowClone.Repo
  alias StackoverflowClone.StackOverflow.RecentSearch
  import Ecto.Query

  def save_search(query) do
    %RecentSearch{}
    |> RecentSearch.changeset(%{question: query})
    |> Repo.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, "Failed to save search: #{inspect(changeset.errors)}"}
    end
  end

  def get_recent_searches do
    RecentSearch
    |> order_by(desc: :searched_at)
    |> limit(5)
    |> Repo.all()
  rescue
    _ -> []
  end
end
