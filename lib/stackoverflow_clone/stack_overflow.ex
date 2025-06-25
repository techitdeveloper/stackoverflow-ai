defmodule StackoverflowClone.StackOverflow do
  alias StackoverflowClone.StackOverflow.{
    RecentSearches,
    StackOverflowAPI,
    AnswerRanker
  }

  def search_questions(query) when is_binary(query) and byte_size(query) > 0 do
    case RecentSearches.save_search(query) do
      :ok ->
        case StackOverflowAPI.search_questions(query) do
          {:ok, questions} -> {:ok, questions}
          {:error, reason} -> {:error, reason}
        end

      {:error, _reason} ->
        StackOverflowAPI.search_questions(query)
    end
  end

  def search_questions(_), do: {:error, "Invalid query"}

  def get_answers(question_id) when is_binary(question_id) or is_integer(question_id) do
    StackOverflowAPI.get_answers(question_id)
  end

  def rerank_answers(answers, question) when is_list(answers) and is_binary(question) do
    AnswerRanker.rerank_answers(answers, question)
  end

  def get_recent_searches do
    RecentSearches.get_recent_searches()
  end
end
