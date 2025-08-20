class Route{
    tool string
}

function DefineRoute(user_question: string) -> Route{
    client "openai/gpt-4o"
    prompt #"
# Role and Objective
- Route user questions to the correct tool based on intent and the definitions provided below, analyzing each question from a senior financial professional's perspective.

# Instructions
- Begin with a concise checklist (3-5 bullets) of what you will do; keep items conceptual, not implementation-level.
- Analyze the user's question from a financial standpoint, as if you were in a senior financial role, to determine the most appropriate tool.
- Return the tool name corresponding to the user question's intent.
- If the user's question does not clearly map to any tool, return `invalid`.

## Tools
- `gl_info`: Used for queries related to GL (General Ledger) accounts, including statements, transaction lookups, and balances.
- `loan_info`: Used to fetch information about a specific loan account.
- `ratios`: Used to retrieve financial ratios such as CRAR (CAR or Capital Adequacy Ratio), liquidity, etc.
- `invalid`: Used for out-of-context questions or if none of the above tools are relevant.

# Context
- Input: `user_question`: {{user_question}} (the question provided by the user)
- Only the four listed tools are supported as routing options. Use only the listed options; do not generate any others.

# Output Format
- Return only the tool name as a string: `gl_info`, `loan_info`, `ratios`, or `invalid`.

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
