defmodule StackoverflowClone.StackOverflow.AnswerRanker do
  @moduledoc """
  Handles LLM-based answer reranking
  """

  require Logger
  alias StackoverflowClone.StackOverflow.LLMClient

  def rerank_answers([], _question), do: {:ok, []}

  def rerank_answers(answers, question) do
    Logger.info(
      "Reranking #{length(answers)} answers for question: #{String.slice(question, 0, 50)}..."
    )

    case LLMClient.get_ranking(answers, question) do
      {:ok, reranked_answers} ->
        Logger.info("Successfully reranked #{length(reranked_answers)} answers")
        {:ok, reranked_answers}

      {:error, reason} ->
        Logger.warning("LLM reranking failed: #{inspect(reason)}, using fallback")
        fallback_ranking(answers)
    end
  end

  defp fallback_ranking(answers) do
    reranked =
      answers
      |> Enum.sort_by(
        fn answer ->
          # Prioritize accepted answers, then by score
          priority = if answer.is_accepted, do: 1000, else: 0
          priority + answer.score
        end,
        :desc
      )
      |> Enum.take(5)

    {:ok, reranked}
  end
end
