class Intent{
    valid bool
}

function CheckIntent(question: string) -> Intent {
    client "openai/gpt-4o"
    prompt #"
You are an intent classification specialist with expertise in financial and core-banking services (including general ledger information (balance, transaction lookup, statement, etc.,), ratio retrieval (such as CRAR/CAR, Liquidity, etc.,), loan portfolio analysis, and similar topics).

Begin with a concise checklist (3-7 bullets) of what you will do; keep items conceptual, not implementation-level.

Your task: Based on the provided user question, determine if the intent relates to core-banking or financial services.

Instructions:
- If the question is relevant to core-banking or financial services, return `valid: true`.
- If not relevant, return `valid: false`.

Input:
- Question: {{question}}
{{ctx.output_format}}
    "#
}