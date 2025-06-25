# StackoverflowClone

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Tech Stack

  * Backend: Elixir/Phoenix LiveView
  * Database: PostgreSQL with Ecto
  * Frontend: Phoenix LiveView with TailwindCSS
  * AI Integration: Google Gemini API for answer reranking
  * External API: Stack Overflow API for question/answer data
  * HTTP Client: HTTPoison for API calls

## Prerequisites

  * Elixir 1.17+ and Erlang/OTP 24+
  * PostgreSQL 12+
  * Node.js 16+ (for asset compilation)
  * Google API Key with Gemini API access

## Install Dependencies

  * mix deps.get

## Database Setup
`mix ecto.create`
`mix ecto.migrate`

In the dev.exs file replace these with your information
  `username: "postgres",`
  `password: "postgres",`
  `hostname: "localhost",`
  `database: "stackoverflow_clone_dev"`

## Start the application
In your terminal do this
`export GOOGLE_API_KEY="your_google_api_key_here"`

`mix phx.server`
or
`iex -S mix phx.server`

## NOTE:
Once you click the search button, a list of answers will appear, when you click on any of the answers then scroll down to toggle for the Ai re-ranking