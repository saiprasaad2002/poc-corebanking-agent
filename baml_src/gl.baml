class GLParams{
    account_number string[] @description("Mandatory number for the general ledger to fetch data")
    branch string[]? @description("The branch name of the GL account to fetch the data from. Optional Parameter")
    clarification bool @description("False, if the mandatory params of account number is present, True if account number is missing")
    reason string? @description("The missing parameter is mentioned here, this acts as a follow up to the user")
}

function FetchGLParams(user_question: string) -> GLParams{
    client "openai/gpt-4o"
    prompt #"
        You're an expert banking assistant where you'll be fetching some information (ie) 
        parameters from the user's question regarding the general ledger information, that will be used to query the database and fetch the result
        Here's the user's question: {{user_question}}
        Example GL account numbers: A01, 012, 001-120,115-RA1
        Example branches: Chennai, Mumbai, Bangalore, Kolkata

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
