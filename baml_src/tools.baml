enum Tools{
    @@dynamic
}

class Toolvalidation{
    valid bool
    tool_name string[]?
    description string[]?
    reasoning string? @description("The reasoning behind the tool validation")
}

class Invocations{
    tool_name string
    parameters string[] | int[] @description("string parameters should be stored as string datatype and for numbers, it should be stored as int datatype")
}

class ClarityCheck{
    clarity bool
    functioncall Invocations[]? @description("The respective function names and the parameters for it is defined here")
    reasoning string? @description("The reasoning behind the clarity check decision")
}

function ValidateToolCalling(user_question: string, tools:string[], description: string[],user_role:string) -> Toolvalidation {
    client "openai/gpt-4o"
    prompt #"
        You are an expert in tool validation and your
        role is a financial expert and a well-know expert in core-banking services.
        Given the user's question, determine if the tool calling is valid or not.
        If the user's question fall under one of those valid tools to be called then return valid as true and give the tool_name to be called and it's respective description (which contains the parameters mandatorily required by the function (tool) to be called) as it is without any modification.
        Even if the parameters don't match but the tool call can be achieved with the user's question, then give the reasoning to it.
        If the user's question doesn't fall under any of those valid tools are needed, return valid as false.

        There are some tools which are specific to only certain roles. Check with the description and the user role and decide the validity
        User role: {{user_role}}
        Question: {{user_question}}

        Allowed Tools:
        {% for tool in tools %}
            -{{tool}}
        {% endfor %}

        Descriptions:
        {% for description in description%}
            -{{description}}
        {% endfor %}

        {{ctx.output_format}}
    "#
}

function Claritycheckfunction(user_question:string, tools:string[], description:string[],user_role:string) -> ClarityCheck {
    client "openai/gpt-4o"
    prompt #"
        You are an expert in clarity checking and your
        role is a financial expert and a well-know expert in core-banking services.
        Given the user's question, the tool to be called and the description of the tool which contains the parameters mandatorily required by the function (tool) to be called
        determine if the user's question is clear enough containing the parameters required by the function to be called
        If the user's question is clear enough, return clarity as true, give the tool name to be called and extract the parameters from the user's question
        If the user's question is not clear enough, return clarity as false and give the reasoning behind the clarity check decision
        Question: {{user_question}}
        Tool to be called: {% for tool in tools %}
            -{{tool}}
        {% endfor %}
        Description of the tool: {{description}}
        User role: {{user_role}}
        {{ctx.output_format}}
    "#
}