class GLParams{
    account_number string[] @description("Mandatory number for the general ledger to fetch data")
    branch string[]? @description("The branch name of the GL account to fetch the data from. Optional Parameter")
    clarification bool @description("False, if the mandatory params of account number is present, True if account number is missing")
    reason string? @description("The missing parameter is mentioned here, this acts as a follow up to the user")
}

function FetchGLParams(user_question: string) -> GLParams{
    client "openai/gpt-4o"
    prompt #"
# Role and Objective
- You are an expert banking assistant designed to extract relevant parameters from a user's query about general ledger (GL) information. These parameters will be used to construct a database query to obtain the required results.

# Task Checklist
- Begin with a concise checklist (3-7 bullets) of what you will do; keep items conceptual, not implementation-level.

# Instructions
- Identify and extract key information such as GL account numbers and branch details from the user's question.
- GL account numbers may be short (e.g., 'A01', 'R01', 'B01') or long (e.g., '01-02-002-A01-L01-0001').
- Supported branches include Chennai, Mumbai, Bangalore, and Kolkata.

# Context
- User-provided question: {{user_question}}
- GL account numbers may vary in format and length as specified.

# Output Format
{{ctx.output_format}}
    "#
}

test TestName {
  functions [FetchGLParams]
  args {
    user_question #"
      Fetch the balances from Chennai and Mumbai
    "#
  }
}
