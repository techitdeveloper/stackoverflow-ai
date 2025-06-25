defmodule StackoverflowClone.StackOverflow.LLMClient do
  @moduledoc """
  LLM client for answer ranking
  """

  require Logger

  @url "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"
  @timeout 30_000

  def get_ranking(answers, question) do
    with {:ok, api_key} <- get_api_key(),
         {:ok, prompt} <- build_prompt(answers, question),
         {:ok, response} <- call_gemini(prompt, api_key),
         {:ok, ranking} <- parse_ranking_response(response, answers) do
      {:ok, ranking}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_api_key do
    case System.get_env("GOOGLE_API_KEY") do
      nil -> {:error, "GOOGLE_API_KEY not set"}
      key -> {:ok, key}
    end
  end

  defp build_prompt(answers, question) do
    answer_summaries =
      answers
      |> Enum.with_index(1)
      |> Enum.map(fn {answer, idx} ->
        clean_body = clean_html(answer.body)
        summary = String.slice(clean_body, 0, 300)

        "#{idx}. [Score: #{answer.score}#{if answer.is_accepted, do: ", ACCEPTED", else: ""}] #{summary}..."
      end)
      |> Enum.join("\n\n")

    prompt = """
    Question: "#{question}"

    Here are the available answers with their Stack Overflow scores:

    #{answer_summaries}

    Please rerank these answers from most relevant/helpful to least relevant for answering the question.
    Consider: accuracy, completeness, code quality, and practical usefulness.

    Respond with ONLY the numbers separated by commas (e.g., "3,1,4,2,5") representing the new order from best to worst.
    """

    {:ok, prompt}
  end

  defp call_gemini(prompt, api_key) do
    Logger.info("Calling Gemini API for ranking...")

    headers = [{"Content-Type", "application/json"}]

    payload = %{
      contents: [
        %{
          parts: [
            %{
              text: """
              You are an expert programmer who ranks Stack Overflow answers by relevance and quality.

              #{prompt}
              """
            }
          ]
        }
      ],
      generationConfig: %{
        maxOutputTokens: 100,
        temperature: 0.1
      }
    }

    case HTTPoison.post("#{@url}?key=#{api_key}", Jason.encode!(payload), headers,
           timeout: @timeout,
           recv_timeout: @timeout
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.info("Received response from Gemini")
        parse_gemini_response(body)

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        Logger.error("Gemini API returned #{status}: #{body}")
        {:error, "Gemini API error: #{status}"}

      {:error, error} ->
        Logger.error("HTTP request to Gemini failed: #{inspect(error)}")
        {:error, "Network error: #{inspect(error)}"}
    end
  end

  defp parse_gemini_response(body) do
    case Jason.decode(body) do
      {:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}} | _]}} ->
        cleaned_response = String.trim(text)
        Logger.info("Gemini response: '#{cleaned_response}'")
        {:ok, cleaned_response}

      {:ok, response} ->
        Logger.error("Unexpected Gemini response structure: #{inspect(response)}")
        {:error, "Unexpected Gemini response structure"}

      {:error, decode_error} ->
        Logger.error("JSON decode error: #{inspect(decode_error)}")
        {:error, "Failed to parse Gemini response"}
    end
  end

  defp parse_ranking_response(response, answers) do
    case String.split(response, ",") do
      [_ | _] = indices ->
        try do
          answers_count = length(answers)

          reranked_indices =
            indices
            |> Enum.map(&String.trim/1)
            |> Enum.map(&String.to_integer/1)
            |> Enum.filter(fn idx -> idx >= 1 and idx <= answers_count end)
            |> Enum.uniq()

          reranked_answers =
            reranked_indices
            |> Enum.map(fn idx -> Enum.at(answers, idx - 1) end)
            |> Enum.filter(&(&1 != nil))

          # Add any missing answers at the end
          missing_answers = answers -- reranked_answers
          final_answers = reranked_answers ++ missing_answers

          {:ok, final_answers}
        rescue
          _ -> {:error, "Could not parse ranking response"}
        end

      [] ->
        {:error, "Empty ranking response"}
    end
  end

  defp clean_html(html_text) when is_binary(html_text) do
    html_text
    |> String.replace(~r/<[^>]*>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp clean_html(_), do: ""
end
