defmodule StackoverflowClone.StackOverflow.StackOverflowAPI do
  @moduledoc """
  Stack Overflow API client
  """

  require Logger

  @base_url "https://api.stackexchange.com/2.3"
  @default_params [site: "stackoverflow"]
  @timeout 30_000

  def search_questions(query) do
    url = "#{@base_url}/search/advanced"

    params =
      [
        order: "desc",
        sort: "relevance",
        q: query,
        pagesize: 10
      ] ++ @default_params

    Logger.info("Searching Stack Overflow for: #{query}")

    case make_request(url, params) do
      {:ok, %{"items" => items}} ->
        questions = Enum.map(items, &format_question/1)
        Logger.info("Found #{length(questions)} questions")
        {:ok, questions}

      {:error, reason} ->
        Logger.error("Stack Overflow search failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_answers(question_id) do
    url = "#{@base_url}/questions/#{question_id}/answers"

    params =
      [
        order: "desc",
        sort: "votes",
        filter: "withbody",
        pagesize: 10
      ] ++ @default_params

    Logger.info("Fetching answers for question: #{question_id}")

    case make_request(url, params) do
      {:ok, %{"items" => items}} ->
        answers = Enum.map(items, &format_answer/1)
        Logger.info("Found #{length(answers)} answers")
        {:ok, answers}

      {:error, reason} ->
        Logger.error("Failed to fetch answers: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions
  defp make_request(url, params) do
    case HTTPoison.get(url, [], params: params, timeout: @timeout, recv_timeout: @timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        Logger.error("Stack Overflow API returned #{status}: #{body}")
        {:error, "API returned status #{status}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, "Network error: #{inspect(reason)}"}
    end
  end

  defp format_question(item) do
    %{
      id: item["question_id"],
      title: item["title"],
      body: Map.get(item, "body", ""),
      score: item["score"],
      view_count: item["view_count"],
      creation_date: item["creation_date"],
      tags: item["tags"] || [],
      link: item["link"]
    }
  end

  defp format_answer(item) do
    %{
      id: item["answer_id"],
      body: item["body"],
      score: item["score"],
      is_accepted: item["is_accepted"] || false,
      creation_date: item["creation_date"]
    }
  end
end
