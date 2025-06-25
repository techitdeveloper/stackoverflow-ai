# defmodule StackoverflowClone.StackOverflow do
#   require Logger
#   alias StackoverflowClone.Repo
#   alias StackoverflowClone.StackOverflow.RecentSearch
#   import Ecto.Query

#   # Schema for recent searches
#   defmodule RecentSearch do
#     use Ecto.Schema
#     import Ecto.Changeset

#     schema "recent_searches" do
#       field :question, :string
#       field :searched_at, :naive_datetime

#       timestamps()
#     end

#     def changeset(search, attrs) do
#       search
#       |> cast(attrs, [:question])
#       |> validate_required([:question])
#       |> put_change(:searched_at, NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second))
#     end
#   end

#   # Search Stack Overflow API
#   def search_questions(query) do
#     # Save to recent searches
#     save_recent_search(query)

#     url = "https://api.stackexchange.com/2.3/search/advanced"
#     params = [
#       order: "desc",
#       sort: "relevance",
#       q: query,
#       site: "stackoverflow",
#       pagesize: 10
#     ]

#     case HTTPoison.get(url, [], params: params) do
#       {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
#         case Jason.decode(body) do
#           {:ok, %{"items" => items}} ->
#             {:ok, format_questions(items)}
#           {:error, _} ->
#             {:error, "Failed to parse response"}
#         end
#       {:error, _} ->
#         {:error, "Failed to fetch from Stack Overflow"}
#     end
#   end

#   # Get answers for a question
#   def get_answers(question_id) do
#     url = "https://api.stackexchange.com/2.3/questions/#{question_id}/answers"
#     params = [
#       order: "desc",
#       sort: "votes",
#       site: "stackoverflow",
#       filter: "withbody",
#       pagesize: 10
#     ]

#     case HTTPoison.get(url, [], params: params) do
#       {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
#         case Jason.decode(body) do
#           {:ok, %{"items" => items}} ->
#             {:ok, format_answers(items)}
#           {:error, _} ->
#             {:error, "Failed to parse answers"}
#         end
#       {:error, _} ->
#         {:error, "Failed to fetch answers"}
#     end
#   end

#   # LLM reranking with OpenAI
#   def rerank_answers(answers, question) do
#     case get_openai_ranking(answers, question) do
#       {:ok, reranked} -> reranked
#       {:error, reason} ->
#         IO.puts("LLM reranking failed: #{inspect(reason)}")
#         # Fallback to simple scoring
#         answers
#         |> Enum.sort_by(& &1.score, :desc)
#         |> Enum.take(5)
#     end
#   end

#   defp get_openai_ranking(answers, question) do
#     Logger.info("Reranking #{length(answers)} answers for question: #{String.slice(question, 0, 50)}...")

#     if length(answers) == 0 do
#       Logger.info("No answers to rerank")
#       {:ok, []}
#     else
#       # Prepare answers for LLM with clean text
#       answer_summaries = answers
#       |> Enum.with_index(1)
#       |> Enum.map(fn {answer, idx} ->
#         clean_body = clean_html(answer.body)
#         summary = String.slice(clean_body, 0, 300)
#         "#{idx}. [Score: #{answer.score}#{if answer.is_accepted, do: ", ACCEPTED", else: ""}] #{summary}..."
#       end)
#       |> Enum.join("\n\n")

#       prompt = """
#       Question: "#{question}"

#       Here are the available answers with their Stack Overflow scores:

#       #{answer_summaries}

#       Please rerank these answers from most relevant/helpful to least relevant for answering the question.
#       Consider: accuracy, completeness, code quality, and practical usefulness.

#       Respond with ONLY the numbers separated by commas (e.g., "3,1,4,2,5") representing the new order from best to worst.
#       """

#       Logger.info("Sending #{length(answers)} answers to Gemini for reranking")

#       case call_openai(prompt) do
#         {:ok, response} ->
#           Logger.info("Got ranking response: '#{response}'")
#           case parse_ranking_response(response, answers) do
#             {:ok, reranked} ->
#               Logger.info("Successfully reranked #{length(reranked)} answers")
#               {:ok, reranked}
#             {:error, reason} ->
#               Logger.warning("Ranking parse failed: #{reason}, using fallback")
#               fallback_ranking(answers)
#           end
#         {:error, reason} ->
#           Logger.error("Gemini call failed: #{reason}")
#           {:error, reason}
#       end
#     end
#   end

#   defp call_openai(prompt) do
#     # Using Google Gemini for free tier
#     call_gemini(prompt)
#   end

#   defp call_gemini(prompt) do
#     Logger.info("calling gemini...")
#     Logger.info("Prompt being sent: #{String.slice(prompt, 0, 200)}...") # Debug log

#     url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"
#     api_key = System.get_env("GOOGLE_API_KEY")

#     if is_nil(api_key) do
#       {:error, "GOOGLE_API_KEY not set"}
#     else
#       headers = [{"Content-Type", "application/json"}]

#       payload = %{
#         contents: [
#           %{
#             parts: [
#               %{text: """
#               You are an expert programmer who ranks Stack Overflow answers by relevance and quality.

#               #{prompt}
#               """}
#             ]
#           }
#         ],
#         generationConfig: %{
#           maxOutputTokens: 100,  # Increased from 50 to allow for comma-separated response
#           temperature: 0.1
#         }
#       }

#       case HTTPoison.post("#{url}?key=#{api_key}", Jason.encode!(payload), headers) do
#         {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
#           Logger.info("Raw response: #{body}")
#           case Jason.decode(body) do
#             {:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}} | _]}} ->
#               cleaned_response = String.trim(text)
#               Logger.info("Cleaned response: '#{cleaned_response}'")
#               {:ok, cleaned_response}
#             {:ok, response} ->
#               Logger.error("Unexpected Gemini response structure: #{inspect(response)}")
#               {:error, "Unexpected Gemini response: #{inspect(response)}"}
#             {:error, decode_error} ->
#               Logger.error("JSON decode error: #{inspect(decode_error)}")
#               {:error, "Failed to parse Gemini response"}
#           end
#         {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
#           Logger.error("Gemini API HTTP error: #{status} - #{body}")
#           {:error, "Gemini API error: #{status} - #{body}"}
#         {:error, error} ->
#           Logger.error("HTTP request failed: #{inspect(error)}")
#           {:error, "HTTP request failed: #{inspect(error)}"}
#       end
#     end
#   end

#   defp parse_ranking_response(response, answers) do
#     # Parse the response like "3,1,4,2,5"
#     case String.split(response, ",") do
#       indices when length(indices) > 0 ->
#         try do
#           reranked_indices =
#             indices
#             |> Enum.map(&String.trim/1)
#             |> Enum.map(&String.to_integer/1)
#             |> Enum.filter(fn idx -> idx >= 1 and idx <= length(answers) end)
#             |> Enum.uniq()

#           reranked_answers =
#             reranked_indices
#             |> Enum.map(fn idx -> Enum.at(answers, idx - 1) end)
#             |> Enum.filter(& &1 != nil)

#           # Add any missing answers at the end
#           missing_answers = answers -- reranked_answers
#           final_answers = reranked_answers ++ missing_answers

#           {:ok, final_answers}
#         rescue
#           _ -> {:error, "Could not parse ranking response"}
#         end
#       _ ->
#         {:error, "Invalid ranking format"}
#     end
#   end

#   defp fallback_ranking(answers) do
#     {:ok,
#       answers
#       |> Enum.sort_by(fn answer ->
#         # Prioritize accepted answers, then by score
#         priority = if answer.is_accepted, do: 1000, else: 0
#         priority + answer.score
#       end, :desc)
#       |> Enum.take(5)
#     }
#   end

#   defp clean_html(html_text) when is_binary(html_text) do
#     html_text
#     |> String.replace(~r/<[^>]*>/, " ")  # Remove HTML tags
#     |> String.replace(~r/\s+/, " ")      # Normalize whitespace
#     |> String.trim()
#   end

#   defp clean_html(_), do: ""

#   # Get recent searches
#   def get_recent_searches do
#     RecentSearch
#     |> order_by(desc: :searched_at)
#     |> limit(5)
#     |> Repo.all()
#   end

#   # Private functions
#   defp save_recent_search(query) do
#     %RecentSearch{}
#     |> RecentSearch.changeset(%{question: query})
#     |> Repo.insert()
#   end

#   defp format_questions(items) do
#     Enum.map(items, fn item ->
#       %{
#         id: item["question_id"],
#         title: item["title"],
#         body: Map.get(item, "body", ""),
#         score: item["score"],
#         view_count: item["view_count"],
#         creation_date: item["creation_date"],
#         tags: item["tags"] || [],
#         link: item["link"]
#       }
#     end)
#   end

#   defp format_answers(items) do
#     Enum.map(items, fn item ->
#       %{
#         id: item["answer_id"],
#         body: item["body"],
#         score: item["score"],
#         is_accepted: item["is_accepted"] || false,
#         creation_date: item["creation_date"]
#       }
#     end)
#   end
# end

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
