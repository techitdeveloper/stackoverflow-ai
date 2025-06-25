# defmodule StackoverflowCloneWeb.QuestionLive do
#   use StackoverflowCloneWeb, :live_view
#   alias StackoverflowClone.StackOverflow

#   def mount(_params, _session, socket) do
#     socket =
#       socket
#       |> assign(:question, "")
#       |> assign(:questions, [])
#       |> assign(:selected_question, nil)
#       |> assign(:answers, [])
#       |> assign(:reranked_answers, [])
#       |> assign(:loading, false)
#       |> assign(:reranking, false)
#       |> assign(:view_mode, "original")
#       |> assign(:recent_searches, StackOverflow.get_recent_searches())

#     {:ok, socket, layout: false}
#   end

#   def handle_event("search", %{"question" => question}, socket) when question != "" do
#     socket = assign(socket, :loading, true)
#     send(self(), {:search_questions, question})
#     {:noreply, assign(socket, :question, question)}
#   end

#   def handle_event("search", _params, socket) do
#     {:noreply, socket}
#   end

#   def handle_event("select_question", %{"id" => id}, socket) do
#     question = Enum.find(socket.assigns.questions, &(&1.id == String.to_integer(id)))
#     socket =
#       socket
#       |> assign(:selected_question, question)
#       |> assign(:loading, true)
#     send(self(), {:get_answers, id})
#     {:noreply, socket}
#   end

#   def handle_event("toggle_view", %{"mode" => mode}, socket) do
#     {:noreply, assign(socket, :view_mode, mode)}
#   end

#   def handle_event("use_recent", %{"question" => question}, socket) do
#     socket =
#       socket
#       |> assign(:loading, true)
#       |> assign(:question, question)
#     send(self(), {:search_questions, question})
#     {:noreply, socket}
#   end

#   def handle_info({:search_questions, question}, socket) do
#     case StackOverflow.search_questions(question) do
#       {:ok, questions} ->
#         socket =
#           socket
#           |> assign(:questions, questions)
#           |> assign(:loading, false)
#           |> assign(:recent_searches, StackOverflow.get_recent_searches())
#         {:noreply, socket}
#       {:error, _error} ->
#         socket =
#           socket
#           |> assign(:loading, false)
#           |> put_flash(:error, "Failed to search questions")
#         {:noreply, socket}
#     end
#   end

#   def handle_info({:get_answers, question_id}, socket) do
#     case StackOverflow.get_answers(question_id) do
#       {:ok, answers} ->
#         socket =
#           socket
#           |> assign(:answers, answers)
#           |> assign(:loading, false)
#           |> assign(:reranking, true)

#         # Start LLM reranking in background
#         send(self(), {:rerank_answers, answers, socket.assigns.question})
#         {:noreply, socket}
#       {:error, _error} ->
#         socket =
#           socket
#           |> assign(:loading, false)
#           |> put_flash(:error, "Failed to get answers")
#         {:noreply, socket}
#     end
#   end

#   def handle_info({:rerank_answers, answers, question}, socket) do
#     reranked = StackOverflow.rerank_answers(answers, question)
#     socket =
#       socket
#       |> assign(:reranked_answers, reranked)
#       |> assign(:reranking, false)
#     {:noreply, socket}
#   end

#   def render(assigns) do
#     ~H"""
#     <div class="max-w-6xl mx-auto p-4">
#       <!-- Header -->
#       <div class="mb-6">
#         <h1 class="text-3xl font-bold text-gray-900 mb-4">Stack Overflow Clone</h1>

#         <!-- Search Form -->
#         <form phx-submit="search" class="mb-4">
#           <div class="flex gap-2">
#             <input
#               type="text"
#               name="question"
#               value={@question}
#               placeholder="Search for questions..."
#               class="flex-1 px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
#             />
#             <button
#               type="submit"
#               disabled={@loading}
#               class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
#             >
#               <%= if @loading, do: "Searching...", else: "Search" %>
#             </button>
#           </div>
#         </form>

#         <!-- Recent Searches -->
#         <%= if length(@recent_searches) > 0 do %>
#           <div class="mb-4">
#             <h3 class="text-sm font-medium text-gray-700 mb-2">Recent Searches:</h3>
#             <div class="flex flex-wrap gap-2">
#               <%= for search <- @recent_searches do %>
#                 <button
#                   phx-click="use_recent"
#                   phx-value-question={search.question}
#                   class="px-3 py-1 text-sm bg-gray-100 hover:bg-gray-200 rounded-full"
#                 >
#                   <%= search.question %>
#                 </button>
#               <% end %>
#             </div>
#           </div>
#         <% end %>
#       </div>

#       <!-- Questions List -->
#       <%= if @loading and length(@questions) == 0 do %>
#         <div class="text-center py-8">
#           <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
#           <p class="mt-2 text-gray-600">Searching questions...</p>
#         </div>
#       <% end %>

#       <%= if length(@questions) > 0 do %>
#         <div class="mb-6">
#           <h2 class="text-xl font-semibold mb-4">Search Results (<%= length(@questions) %> found)</h2>
#           <div class="space-y-4">
#             <%= for question <- @questions do %>
#               <div class="border border-gray-200 rounded-lg p-4 hover:shadow-md hover:border-blue-300 cursor-pointer transition-all"
#                    phx-click="select_question" phx-value-id={question.id}>
#                 <h3 class="text-lg font-medium text-blue-600 hover:text-blue-800">
#                   <%= question.title %>
#                 </h3>
#                 <div class="flex items-center gap-4 mt-2 text-sm text-gray-600">
#                   <span class="flex items-center gap-1">
#                     <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
#                       <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 11l5-5m0 0l5 5m-5-5v12"></path>
#                     </svg>
#                     <%= question.score %>
#                   </span>
#                   <span class="flex items-center gap-1">
#                     <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
#                       <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
#                       <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
#                     </svg>
#                     <%= question.view_count %>
#                   </span>
#                   <%= if length(question.tags) > 0 do %>
#                     <div class="flex gap-1">
#                       <%= for tag <- Enum.take(question.tags, 3) do %>
#                         <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded text-xs">
#                           <%= tag %>
#                         </span>
#                       <% end %>
#                     </div>
#                   <% end %>
#                 </div>
#               </div>
#             <% end %>
#           </div>
#         </div>
#       <% end %>

#       <!-- Selected Question and Answers -->
#       <%= if @selected_question do %>
#         <div class="border-t pt-6">
#           <div class="mb-4">
#             <h2 class="text-2xl font-bold mb-2"><%= @selected_question.title %></h2>
#             <div class="flex items-center gap-4 text-sm text-gray-600 mb-4">
#               <span>Score: <%= @selected_question.score %></span>
#               <span>Views: <%= @selected_question.view_count %></span>
#             </div>
#           </div>

#           <%= if length(@answers) > 0 do %>
#             <!-- View Toggle -->
#             <div class="mb-4">
#               <div class="flex gap-2">
#                 <button
#                   phx-click="toggle_view"
#                   phx-value-mode="original"
#                   class={["px-4 py-2 rounded-md",
#                           if(@view_mode == "original", do: "bg-blue-600 text-white", else: "bg-gray-200")]}
#                 >
#                   Original Order
#                 </button>
#                 <button
#                   phx-click="toggle_view"
#                   phx-value-mode="reranked"
#                   disabled={@reranking}
#                   class={["px-4 py-2 rounded-md flex items-center gap-2",
#                           if(@view_mode == "reranked", do: "bg-blue-600 text-white", else: "bg-gray-200"),
#                           if(@reranking, do: "opacity-50 cursor-not-allowed", else: "")]}
#                 >
#                   <%= if @reranking do %>
#                     <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-current"></div>
#                     AI Reranking...
#                   <% else %>
#                     🤖 AI Reranked
#                   <% end %>
#                 </button>
#               </div>
#               <%= if @view_mode == "reranked" and not @reranking do %>
#                 <p class="text-sm text-gray-600 mt-2">
#                   ✨ These answers have been reordered by AI based on relevance to your question
#                 </p>
#               <% end %>
#             </div>

#             <!-- Answers -->
#             <div class="space-y-6">
#               <%= for answer <- (if @view_mode == "reranked", do: @reranked_answers, else: @answers) do %>
#                 <div class="border border-gray-200 rounded-lg p-4 bg-white">
#                   <%= if answer.is_accepted do %>
#                     <div class="flex items-center gap-2 mb-3">
#                       <svg class="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
#                         <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
#                       </svg>
#                       <span class="text-green-600 font-medium text-sm">✓ Accepted Answer</span>
#                     </div>
#                   <% end %>

#                   <div class="flex items-start gap-4">
#                     <div class="flex flex-col items-center min-w-[60px]">
#                       <div class="text-2xl font-bold text-gray-700"><%= answer.score %></div>
#                       <div class="text-xs text-gray-500 text-center">votes</div>
#                     </div>
#                     <div class="flex-1">
#                       <div class="answer-content">
#                         <%= if String.contains?(answer.body || "", "<") do %>
#                           <%= raw(answer.body) %>
#                         <% else %>
#                           <p class="whitespace-pre-wrap"><%= answer.body %></p>
#                         <% end %>
#                       </div>
#                       <div class="mt-3 text-xs text-gray-500">
#                         Answer ID: <%= answer.id %>
#                       </div>
#                     </div>
#                   </div>
#                 </div>
#               <% end %>
#             </div>
#           <% else %>
#             <%= if @loading do %>
#               <div class="text-center py-8">
#                 <div class="text-gray-600">Loading answers...</div>
#               </div>
#             <% else %>
#               <div class="text-center py-8">
#                 <div class="text-gray-600">No answers found for this question.</div>
#               </div>
#             <% end %>
#           <% end %>
#         </div>
#       <% end %>
#     </div>
#     """
#   end
# end

defmodule StackoverflowCloneWeb.QuestionLive do
  use StackoverflowCloneWeb, :live_view

  alias StackoverflowClone.StackOverflow
  require Logger

  # State management
  defp initial_assigns do
    %{
      question: "",
      questions: [],
      selected_question: nil,
      answers: [],
      reranked_answers: [],
      loading: false,
      reranking: false,
      view_mode: "original",
      recent_searches: [],
      error: nil
    }
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(initial_assigns())
      |> load_recent_searches()

    {:ok, socket, layout: false}
  end

  # Event handlers
  def handle_event("search", %{"question" => question}, socket) when question != "" do
    socket =
      socket
      |> assign(:loading, true)
      |> assign(:question, question)
      |> clear_error()

    send(self(), {:search_questions, question})
    {:noreply, socket}
  end

  def handle_event("search", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("select_question", %{"id" => id}, socket) do
    case find_question_by_id(socket.assigns.questions, id) do
      nil ->
        {:noreply, put_error(socket, "Question not found")}

      question ->
        socket =
          socket
          |> assign(:selected_question, question)
          |> assign(:loading, true)
          |> clear_error()

        send(self(), {:get_answers, id})
        {:noreply, socket}
    end
  end

  def handle_event("toggle_view", %{"mode" => mode}, socket)
      when mode in ["original", "reranked"] do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  def handle_event("toggle_view", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("use_recent", %{"question" => question}, socket) do
    socket =
      socket
      |> assign(:loading, true)
      |> assign(:question, question)
      |> clear_error()

    send(self(), {:search_questions, question})
    {:noreply, socket}
  end

  def handle_event("clear_error", _params, socket) do
    {:noreply, clear_error(socket)}
  end

  # Async message handlers
  def handle_info({:search_questions, question}, socket) do
    case StackOverflow.search_questions(question) do
      {:ok, questions} ->
        socket =
          socket
          |> assign(:questions, questions)
          |> assign(:loading, false)
          |> load_recent_searches()
          |> clear_error()

        Logger.info("Found #{length(questions)} questions for: #{question}")
        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Search failed: #{inspect(reason)}")

        socket =
          socket
          |> assign(:loading, false)
          |> put_error("Failed to search questions: #{reason}")

        {:noreply, socket}
    end
  end

  def handle_info({:get_answers, question_id}, socket) do
    case StackOverflow.get_answers(question_id) do
      {:ok, answers} ->
        socket =
          socket
          |> assign(:answers, answers)
          |> assign(:loading, false)
          |> assign(:reranking, true)
          |> clear_error()

        Logger.info("Found #{length(answers)} answers for question #{question_id}")

        # Start LLM reranking in background
        send(self(), {:rerank_answers, answers, socket.assigns.question})
        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Failed to get answers: #{inspect(reason)}")

        socket =
          socket
          |> assign(:loading, false)
          |> put_error("Failed to get answers: #{reason}")

        {:noreply, socket}
    end
  end

  def handle_info({:rerank_answers, answers, question}, socket) do
    case StackOverflow.rerank_answers(answers, question) do
      {:ok, reranked} ->
        Logger.info("Successfully reranked #{length(reranked)} answers")

        socket =
          socket
          |> assign(:reranked_answers, reranked)
          |> assign(:reranking, false)
          |> clear_error()

        {:noreply, socket}
    end
  end

  # Helper functions
  defp find_question_by_id(questions, id_string) do
    case Integer.parse(id_string) do
      {id, _} -> Enum.find(questions, &(&1.id == id))
      :error -> nil
    end
  end

  defp load_recent_searches(socket) do
    recent_searches = StackOverflow.get_recent_searches()
    assign(socket, :recent_searches, recent_searches)
  end

  defp put_error(socket, message) do
    socket
    |> assign(:error, message)
    |> put_flash(:error, message)
  end

  defp clear_error(socket) do
    assign(socket, :error, nil)
  end

  # View helpers
  defp display_answers(assigns) do
    case assigns.view_mode do
      "reranked" -> assigns.reranked_answers
      _ -> assigns.answers
    end
  end

  defp show_reranking_indicator?(assigns) do
    assigns.view_mode == "reranked" && !assigns.reranking
  end

  defp format_number(nil), do: "0"

  defp format_number(num) when is_integer(num) and num >= 1000 do
    "#{Float.round(num / 1000, 1)}k"
  end

  defp format_number(num), do: to_string(num)

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto p-4">
      <!-- Header -->
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-4">Stack Overflow Clone</h1>
        
    <!-- Error Display -->
        <%= if @error do %>
          <div class="bg-red-50 border border-red-200 rounded-md p-4 mb-4">
            <div class="flex items-center justify-between">
              <div class="flex items-center">
                <svg class="w-5 h-5 text-red-400 mr-2" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                    clip-rule="evenodd"
                  >
                  </path>
                </svg>
                <span class="text-red-800 text-sm">{@error}</span>
              </div>
              <button phx-click="clear_error" class="text-red-400 hover:text-red-600">
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                    clip-rule="evenodd"
                  >
                  </path>
                </svg>
              </button>
            </div>
          </div>
        <% end %>
        
    <!-- Search Form -->
        <form phx-submit="search" class="mb-4">
          <div class="flex gap-2">
            <input
              type="text"
              name="question"
              value={@question}
              placeholder="Search for questions..."
              class="flex-1 px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              autocomplete="off"
            />
            <button
              type="submit"
              disabled={@loading}
              class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {if @loading, do: "Searching...", else: "Search"}
            </button>
          </div>
        </form>
        
    <!-- Recent Searches -->
        <%= if length(@recent_searches) > 0 do %>
          <div class="mb-4">
            <h3 class="text-sm font-medium text-gray-700 mb-2">Recent Searches:</h3>
            <div class="flex flex-wrap gap-2">
              <%= for search <- @recent_searches do %>
                <button
                  phx-click="use_recent"
                  phx-value-question={search.question}
                  class="px-3 py-1 text-sm bg-gray-100 hover:bg-gray-200 rounded-full transition-colors"
                  title="Search: {@search.question}>"
                >
                  {String.slice(search.question, 0, 30)}{if String.length(search.question) > 30,
                    do: "..."}
                </button>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
      
    <!-- Loading State -->
      <%= if @loading and length(@questions) == 0 do %>
        <div class="text-center py-12">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600">
          </div>
          <p class="mt-2 text-gray-600">Searching questions...</p>
        </div>
      <% end %>
      
    <!-- Questions List -->
      <%= if length(@questions) > 0 do %>
        <div class="mb-8">
          <h2 class="text-xl font-semibold mb-4">
            Search Results <span class="text-gray-500 font-normal">({length(@questions)} found)</span>
          </h2>
          <div class="space-y-4">
            <%= for question <- @questions do %>
              <div
                class="border border-gray-200 rounded-lg p-4 hover:shadow-md hover:border-blue-300 cursor-pointer transition-all"
                phx-click="select_question"
                phx-value-id={question.id}
              >
                <h3 class="text-lg font-medium text-blue-600 hover:text-blue-800 mb-2">
                  {question.title}
                </h3>
                <div class="flex items-center gap-4 text-sm text-gray-600">
                  <span class="flex items-center gap-1" title="Score">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M7 11l5-5m0 0l5 5m-5-5v12"
                      >
                      </path>
                    </svg>
                    {format_number(question.score)}
                  </span>
                  <span class="flex items-center gap-1" title="Views">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                      >
                      </path>
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                      >
                      </path>
                    </svg>
                    {format_number(question.view_count)}
                  </span>
                  <%= if length(question.tags) > 0 do %>
                    <div class="flex gap-1 ml-2">
                      <%= for tag <- Enum.take(question.tags, 3) do %>
                        <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded text-xs">
                          {tag}
                        </span>
                      <% end %>
                      <%= if length(question.tags) > 3 do %>
                        <span class="text-xs text-gray-500 px-2 py-1">
                          +{length(question.tags) - 3} more
                        </span>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
      
    <!-- Selected Question and Answers -->
      <%= if @selected_question do %>
        <div class="border-t pt-6">
          <div class="mb-6">
            <h2 class="text-2xl font-bold mb-3">{@selected_question.title}</h2>
            <div class="flex items-center gap-4 text-sm text-gray-600 mb-4">
              <span class="flex items-center gap-1">
                <strong>Score:</strong> {format_number(@selected_question.score)}
              </span>
              <span class="flex items-center gap-1">
                <strong>Views:</strong> {format_number(@selected_question.view_count)}
              </span>
              <%= if length(@selected_question.tags) > 0 do %>
                <div class="flex gap-1">
                  <%= for tag <- @selected_question.tags do %>
                    <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded text-xs">
                      {tag}
                    </span>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

          <%= if length(@answers) > 0 do %>
            <!-- View Toggle -->
            <div class="mb-6">
              <div class="flex gap-2 mb-2">
                <button
                  phx-click="toggle_view"
                  phx-value-mode="original"
                  class={[
                    "px-4 py-2 rounded-md transition-colors",
                    if(@view_mode == "original",
                      do: "bg-blue-600 text-white",
                      else: "bg-gray-200 hover:bg-gray-300"
                    )
                  ]}
                >
                  Original Order
                </button>
                <button
                  phx-click="toggle_view"
                  phx-value-mode="reranked"
                  disabled={@reranking}
                  class={[
                    "px-4 py-2 rounded-md flex items-center gap-2 transition-colors",
                    if(@view_mode == "reranked",
                      do: "bg-blue-600 text-white",
                      else: "bg-gray-200 hover:bg-gray-300"
                    ),
                    if(@reranking, do: "opacity-50 cursor-not-allowed", else: "")
                  ]}
                >
                  <%= if @reranking do %>
                    <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-current"></div>
                    AI Reranking...
                  <% else %>
                    🤖 AI Reranked
                  <% end %>
                </button>
              </div>

              <%= if show_reranking_indicator?(assigns) do %>
                <p class="text-sm text-gray-600">
                  ✨ These answers have been reordered by AI based on relevance to your question
                </p>
              <% end %>
            </div>
            
    <!-- Answers -->
            <div class="space-y-6">
              <%= for {answer, index} <- Enum.with_index(display_answers(assigns), 1) do %>
                <div class="border border-gray-200 rounded-lg p-6 bg-white shadow-sm">
                  <div class="flex items-start gap-4">
                    <!-- Vote Score -->
                    <div class="flex flex-col items-center min-w-[80px]">
                      <%= if @view_mode == "reranked" do %>
                        <div class="text-xs text-blue-600 font-medium mb-1">
                          #{index}
                        </div>
                      <% end %>
                      <div class="text-2xl font-bold text-gray-700">{answer.score}</div>
                      <div class="text-xs text-gray-500 text-center">votes</div>
                      <%= if answer.is_accepted do %>
                        <div class="flex items-center gap-1 mt-2 px-2 py-1 bg-green-100 rounded-full">
                          <svg class="w-4 h-4 text-green-600" fill="currentColor" viewBox="0 0 20 20">
                            <path
                              fill-rule="evenodd"
                              d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                              clip-rule="evenodd"
                            >
                            </path>
                          </svg>
                          <span class="text-green-700 font-medium text-xs">Accepted</span>
                        </div>
                      <% end %>
                    </div>
                    
    <!-- Answer Content -->
                    <div class="flex-1 min-w-0">
                      <div class="answer-content prose prose-sm max-w-none">
                        <%= if String.contains?(answer.body || "", "<") do %>
                          {raw(answer.body)}
                        <% else %>
                          <p class="whitespace-pre-wrap text-gray-800">{answer.body}</p>
                        <% end %>
                      </div>
                      
    <!-- Answer Metadata -->
                      <div class="mt-4 pt-3 border-t border-gray-100">
                        <div class="flex items-center justify-between text-xs text-gray-500">
                          <span>Answer ID: {answer.id}</span>
                          <%= if answer.creation_date do %>
                            <span>
                              Created: {format_timestamp(answer.creation_date)}
                            </span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <!-- No Answers State -->
            <div class="text-center py-12">
              <%= if @loading do %>
                <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mb-4">
                </div>
                <p class="text-gray-600">Loading answers...</p>
              <% else %>
                <svg
                  class="w-16 h-16 text-gray-300 mx-auto mb-4"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9.172 16.172a4 4 0 015.656 0M9 12h6m-6-4h6m2 5.291A7.962 7.962 0 0112 15c-2.34 0-4.291.94-5.709 2.291M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  >
                  </path>
                </svg>
                <p class="text-gray-600 text-lg">No answers found for this question.</p>
                <p class="text-gray-500 text-sm mt-2">
                  This question might not have any answers yet.
                </p>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
      
    <!-- Empty State -->
      <%= if length(@questions) == 0 and not @loading and @question != "" do %>
        <div class="text-center py-12">
          <svg
            class="w-16 h-16 text-gray-300 mx-auto mb-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
            >
            </path>
          </svg>
          <p class="text-gray-600 text-lg">No questions found</p>
          <p class="text-gray-500 text-sm mt-2">
            Try a different search term or check your spelling.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  # Additional helper functions
  defp format_timestamp(unix_timestamp) when is_integer(unix_timestamp) do
    unix_timestamp
    |> DateTime.from_unix!()
    |> DateTime.to_date()
    |> Date.to_string()
  rescue
    _ -> "Unknown"
  end

  defp format_timestamp(_), do: "Unknown"
end
