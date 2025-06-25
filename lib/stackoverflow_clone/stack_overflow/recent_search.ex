defmodule StackoverflowClone.StackOverflow.RecentSearch do
  @moduledoc """
  Schema for recent search queries
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "recent_searches" do
    field :question, :string
    field :searched_at, :naive_datetime

    timestamps()
  end

  @required_fields [:question]
  @optional_fields []

  def changeset(search, attrs) do
    search
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:question, min: 1, max: 500)
    |> put_searched_at()
  end

  defp put_searched_at(changeset) do
    put_change(changeset, :searched_at, NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second))
  end
end
