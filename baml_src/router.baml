class Route{
    tool string
}

function DefineRoute(user_question: string) -> Route{
    client "openai/gpt-4o"
    prompt #"
        You're an expert at routing the user question to the available routes, having their specific tool names (which is defined below)
        Analyse the user question and define the route accordingly. If you couldn't identify the tool from the user question, then return the tool "invalid"
        User Question: {{user_question}}

        Tools:
        gl_info ("To fetch the information about a specific general ledger")
        loan_info ("To fetch the information about a specific loan account")
        ratios ("To fetch the ratios such as CRAR, Liquidity, etc")
        invalid ("Out of context/less relevant tool")

        {{ctx.output_format}}

    "#
}

test TestName {
  functions [DefineRoute]
  args {
    user_question #"
      What's the liquidity ratio
    "#
  }
}
