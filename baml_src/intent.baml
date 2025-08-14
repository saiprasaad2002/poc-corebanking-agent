class Intent{
    valid bool
}

function CheckIntent(question: string) -> Intent {
    client "openai/gpt-4o"
    prompt #"
        You are an expert in intent classification and your
        role is a financial expert and a well-know expert in core-banking services.
        Given the user's question, determine if the user's intent is relevant to any 
        core-banking or financial services. If the intent is relevant, return
        valid as true otherwise return valid as false.
        Question: {{question}}

        {{ctx.output_format}}
    "#
}