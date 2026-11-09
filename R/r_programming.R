#' R Programming Integration Functions
#'
#' Functions for code debugging, explanation, dataset assistance,
#' and code generation with RConsoleAI.
#'
#' @name rchat-programming
#' @keywords internal
NULL

#' Debug R Code with AI
#'
#' Send R code to the AI for debugging and explanation.
#'
#' @param code R code as a string
#' @param context Additional context about the problem
#' @param provider Provider to use (NULL for current)
#' @param model Model name (NULL for auto)
#' @return AI response
#' @export
#' @examples
#' \dontrun{
#' rchat_code("
#' x <- rnorm(100)
#' hist(x)
#' ")
#' }
rchat_code <- function(code, context = "", provider = NULL, model = NULL) {
  pm <- get_provider_manager()
  if (!is.null(provider)) pm$set_provider(provider)
  if (!is.null(model)) pm$set_model(model)
  
  selected_provider <- pm$resolve_provider()
  
  prompt <- paste0(
    "Please analyze the following R code for potential issues, bugs, or improvements.\n",
    "Explain what the code does and identify any problems.\n\n",
    "```r\n", code, "\n```\n"
  )
  
  if (nchar(context) > 0) {
    prompt <- paste0(prompt, "\nAdditional context: ", context)
  }
  
  conversation <- Conversation$new(
    system_prompt = paste(
      rconsoleai_options("system_prompt"),
      "\nYou are an expert R programmer. Analyze code for bugs, performance issues,",
      "style problems, and best practices. Provide clear explanations and fixed code."
    )
  )
  
  process_single_prompt(prompt, selected_provider, conversation,
                        rconsoleai_options("max_tokens"), 0.3)
}

#' Explain R Code
#'
#' Get an explanation of what R code does.
#'
#' @param code R code as a string
#' @param detail Level of detail: "brief", "normal", "detailed"
#' @param provider Provider to use
#' @param model Model name
#' @return AI response
#' @export
#' @examples
#' \dontrun{
#' rchat_explain("
#' model <- lm(mpg ~ wt, data = mtcars)
#' summary(model)
#' ")
#' }
rchat_explain <- function(code, detail = "normal", provider = NULL, model = NULL) {
  pm <- get_provider_manager()
  if (!is.null(provider)) pm$set_provider(provider)
  if (!is.null(model)) pm$set_model(model)
  
  selected_provider <- pm$resolve_provider()
  
  detail_instructions <- switch(detail,
    brief = "Provide a brief 2-3 sentence summary.",
    normal = "Explain what the code does step by step, including the purpose of each line.",
    detailed = "Provide a detailed explanation including statistical concepts, function parameters, and alternatives."
  )
  
  prompt <- paste0(
    "Please explain the following R code.\n\n",
    "```r\n", code, "\n```\n\n",
    detail_instructions
  )
  
  conversation <- Conversation$new(
    system_prompt = paste(
      rconsoleai_options("system_prompt"),
      "\nYou are an expert R instructor. Explain code clearly for learners.",
      "Include the purpose, key functions, and what the output means."
    )
  )
  
  process_single_prompt(prompt, selected_provider, conversation,
                        rconsoleai_options("max_tokens"), 0.3)
}

#' Analyze Dataset with AI
#'
#' Get AI assistance for dataset exploration, visualization suggestions,
#' and statistical analysis recommendations.
#'
#' @param data Data frame or dataset name
#' @param name Dataset name (for context)
#' @param include_data Whether to include sample data (requires consent)
#' @param provider Provider to use
#' @param model Model name
#' @return AI response
#' @export
#' @examples
#' \dontrun{
#' rchat_data(mtcars)
#' rchat_data(iris, include_data = TRUE)
#' }
rchat_data <- function(data, name = NULL, include_data = FALSE,
                       provider = NULL, model = NULL) {
  pm <- get_provider_manager()
  if (!is.null(provider)) pm$set_provider(provider)
  if (!is.null(model)) pm$set_model(model)
  
  selected_provider <- pm$resolve_provider()
  
  # Get dataset name if not provided
  if (is.null(name)) {
    name <- deparse(substitute(data))
  }
  
  # Format dataset summary
  helper <- RContextHelper$new(include_values = include_data)
  summary_text <- helper$format_dataset_summary(data, name)
  
  prompt <- paste0(
    "Please analyze the following dataset and provide:\n",
    "1. A brief description of the dataset\n",
    "2. Suggested visualizations\n",
    "3. Recommended statistical analyses\n",
    "4. Potential data quality issues\n\n",
    summary_text
  )
  
  if (include_data) {
    prompt <- paste0(
      prompt,
      "\n\nNote: Sample data values are included above. Use them to provide specific insights."
    )
  }
  
  conversation <- Conversation$new(
    system_prompt = paste(
      rconsoleai_options("system_prompt"),
      "\nYou are an expert data analyst and statistician.",
      "Provide actionable insights for dataset exploration, visualization, and analysis.",
      "Recommend appropriate R packages and functions."
    )
  )
  
  process_single_prompt(prompt, selected_provider, conversation,
                        rconsoleai_options("max_tokens"), 0.4)
}

#' Generate R Code
#'
#' Generate R code for a specific task.
#'
#' @param task Description of the task
#' @param packages Preferred packages (e.g., "tidyverse", "data.table", "base")
#' @param provider Provider to use
#' @param model Model name
#' @return AI response with code
#' @export
#' @examples
#' \dontrun{
#' rchat("Generate R code for multiple linear regression with diagnostics")
#' }
rchat_generate <- function(task, packages = "tidyverse", provider = NULL, model = NULL) {
  pm <- get_provider_manager()
  if (!is.null(provider)) pm$set_provider(provider)
  if (!is.null(model)) pm$set_model(model)
  
  selected_provider <- pm$resolve_provider()
  
  prompt <- paste0(
    "Generate R code for the following task:\n\n",
    task, "\n\n",
    "Requirements:\n",
    "- Use ", packages, " packages\n",
    "- Include comments explaining each step\n",
    "- Provide a complete, runnable example with sample data if needed\n",
    "- Include basic error handling\n",
    "- Do not use external data files; use built-in datasets or generate synthetic data"
  )
  
  conversation <- Conversation$new(
    system_prompt = paste(
      rconsoleai_options("system_prompt"),
      "\nYou are an expert R programmer. Generate clean, idiomatic, well-commented R code.",
      "Follow best practices for the specified package ecosystem.",
      "Never include code that writes files outside tempdir() or makes network requests."
    )
  )
  
  process_single_prompt(prompt, selected_provider, conversation,
                        rconsoleai_options("max_tokens"), 0.3)
}

#' Ask Question About R Environment
#'
#' Ask the AI a question about the current R environment,
#' including variables, loaded packages, and data.
#'
#' @param question Question to ask
#' @param include_values Whether to include variable values (requires consent)
#' @param provider Provider to use
#' @param model Model name
#' @return AI response
#' @export
#' @examples
#' \dontrun{
#' rchat_env("What variables do I have loaded?")
#' rchat_env("What's in my dataframe df?")
#' }
rchat_env <- function(question, include_values = FALSE, provider = NULL, model = NULL) {
  pm <- get_provider_manager()
  if (!is.null(provider)) pm$set_provider(provider)
  if (!is.null(model)) pm$set_model(model)
  
  selected_provider <- pm$resolve_provider()
  
  # Get environment context
  helper <- RContextHelper$new(include_values = include_values)
  context <- helper$format_for_prompt()
  
  prompt <- paste0(
    "Answer the following question about the current R environment.\n\n",
    "Environment Context:\n", context, "\n\n",
    "Question: ", question
  )
  
  conversation <- Conversation$new(
    system_prompt = paste(
      rconsoleai_options("system_prompt"),
      "\nYou are an expert R programmer. Answer questions about the user's R environment",
      "based on the provided context. Do not assume access to variables not listed."
    )
  )
  
  process_single_prompt(prompt, selected_provider, conversation,
                        rconsoleai_options("max_tokens"), 0.3)
}