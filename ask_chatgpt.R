# Function to  call the GPT API from R
# Credit https://www.r-bloggers.com/2023/03/call-chatgpt-or-really-any-other-api-from-r/

api_key <- "XXXXXX" # Don't share this! 😅

library(httr)
library(stringr)

# Calls the ChatGPT API with the given prompt and returns the answer
ask_chatgpt <- function(prompt) {
  response <- POST(
    url = "https://api.openai.com/v1/chat/completions", 
    add_headers(Authorization = paste("Bearer", api_key)),
    content_type_json(),
    encode = "json",
    body = list(
      model = "gpt-3.5-turbo-16k",
      messages = list(list(
        role = "user", 
        content = prompt
      ))
    )
  )
  str_trim(content(response)$choices[[1]]$message$content)
}
