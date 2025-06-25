defmodule StackoverflowClone.Repo.Migrations.CreateRecentSearches do
  use Ecto.Migration

  def change do
    create table(:recent_searches) do
      add :question, :string, null: false
      add :searched_at, :naive_datetime, default: fragment("NOW()")
      timestamps()
    end

    create index(:recent_searches, [:searched_at])
  end
end
