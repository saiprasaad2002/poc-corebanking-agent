class ComponentDetail {
    source string @description("The name of the table to fetch from. Only the table names mentioned in the schema")
    crieteria string? @description("The fiter value to pass in the to get the desired result. Should be the same as what it's present in the policy document")
    risk string? @description("The risk percentage, or empty if not applicable")
}
                
class Parameters {
    valid bool @description("Validate if the user's question is relevant to the markdown content or not")
    components map<string, ComponentDetail[]>?
        @description("Mapping of component name to list of details, one component can have multiple sources and multiple criterias")
    formula string?
        @description("The formula to achieve the query execution")
    planner string?
        @description("A successful plan/path")
}

function FetchResults(markdown_content: string, user_question: string) -> Parameters{
    client "openai/gpt-4o"
    prompt #"
# Role and Objective
- You are an advanced financial document analyzer and SQL query expert. Your mission is to thoroughly analyze both structured and unstructured markdown policy documents and extract contents that are strongly relevant to the user's question about financial ratios.

# Instructions
- Start by evaluating the validity (relevancy) of the user's question with the markdown content presented. Strongly check for a direct and explicit link between the user's question and the provided policy document content. If there is high relevancy, return the result as "True" and proceed. If not, return "False" and do not proceed with content extraction.
- Do not extract any components or policy document content unless the user's question is found to be explicitly and strongly relevant to the markdown content.
- Begin with a concise checklist (3-7 bullets) of conceptual steps to take; avoid implementation-level detail.
- Ensure a robust, iterative step-by-step methodology to guarantee only highly relevant content is extracted, with strict adherence to preventing blending between different ratios or irrelevant information.
- Work with both structured and unstructured markdown content by fully reviewing the entire policy document for the most strongly relevant sections.
- Use policy document terminology exactly: strictly match all component, source, criteria, and formula names to the policy.
- When extracting the source name for each component from the policy document, ensure the source is matched against the given database schema tables (for example, if the policy document mentions GL as the source, it should be mapped to `gl_account_master`, `gl_account_summary`, or both, depending upon components required by the calculation).

## Stepwise Process

**STEP 0: VALIDITY (RELEVANCY) CHECK**
- Evaluate if the user's question about a financial ratio is directly and explicitly relevant to the content in the policy document (`{{markdown_content}}`).
- If strong relevancy is not established, immediately return "False" and do not proceed.
- If the question is found valid and relevant, return "True" and continue with the detailed extraction process.

**STEP 1: RATIO IDENTIFICATION**
- Extract the exact financial ratio name as mentioned in the user question (`{{user_question}}`).
- State the identified ratio name explicitly.

**STEP 2: COMPREHENSIVE POLICY DOCUMENT ANALYSIS**
- Iterate through the entire provided markdown policy document (`{{markdown_content}}`), regardless of structure, searching for text or sections that are strongly and directly relevant to the ratio in the user question.
- Apply strong iterative extraction and validation at each step to avoid inclusion of any loosely related or extraneous information.

**STEP 3: RELEVANT SECTION EXTRACTION**
- Quote only those specific sections, passages, or paragraphs that have clear, direct association with the identified financial ratio.

**STEP 4: COMPONENT, FORMULA, SOURCE, AND CRITERIA EXTRACTION**
- For each relevant quoted section, extract and map:
  - `component`: Every part of the formula derived from the policy document for the selected ratio.
  - `source`: The database table or entity from which each component must be retrieved. The extracted source name must be correlated and mapped to the correct table(s) in the provided database schema. If the policy uses an ambiguous or shorthand name (e.g., GL), you must determine the appropriate schema table(s) (e.g., `gl_account_master`, `gl_account_summary`, or both) for each component as required for accurate database retrieval.
  - `criteria`: Clear filters or conditions stated in the policy for each component when retrieving from the source.
  - `formula`: The complete calculation or relationship among components as specified.
- Account for multiple sources, criteria, or component details, mirroring everything as stated in the policy document.
- Output components, sources, criteria, and formulas as arrays or objects to capture the exact structure and detail.

## Validation Stage
- Before any output, rigorously validate:
- The extracted formula strictly matches the identified ratio.
- Components, sources (matching to schema tables), and criteria are exclusively associated with the selected ratio, with no cross-mixing.
- Every relevant detail in tables, text, or figures is fully captured and mapped.
- Names and terms for sources/components exactly mirror those in the policy document and are appropriately mapped to the schema.
- Optional parameters or criteria are included only if unambiguously stated in the policy document.
- Repeat iterations and reviews if any ambiguity or irrelevance is detected, to ensure only content of the highest relevance is included.

# Planning and Output Policy
- Return a result only once all validation checks for strong relevance, question validity, and precision are passed.
- Return a result only once all validation checks for strong relevance and precision are passed.
- If any piece cannot be identified, validated, or found to be strongly relevant, return the null/empty output structure immediately.

# SQL Query Planning
- Based on the extracted and validated components, formula, sources (mapped and aligned to specific tables in the provided schema), and criteria, propose a clear planner. This planner should explain the reasoning and precise steps for building an accurate SQL query. The plan must clearly specify the source name(s) as matched to the schema, the components, criteria, and formula, describing in detail how the database query operation should proceed to fulfill policy requirements and user questions.

### Database Schema (reference for accurate column and table usage for source extraction)
- `gl_account_master(gl_acct_id, gl_account, branch, account_name, account_category, sub_category)`
- `gl_account_summary(gl_acct_id, acct_currency, ledger_balance, last_transaction_date)`
- `loan_portfolio(loan_id, branch, loan_type, loan_product, risk_weight_percentage, principal_amount, interest_rate, purpose, tenor_months, repayment_type, charge_collected, collateral_value, risk_class, outstanding_balance, accrued_interest, currency)`

{{ctx.output_format}}
    "#
}

class SqlQuery {
    sql_query string @description("The final optimized SQL Query")
}

function SqlQueryGenerator(components: Parameters) -> SqlQuery{
    client CustomSonnet
    prompt #"
# Role and Objective
- You are an advanced SQL query generator. Your inputs are objects that include extracted policy components, sources, criteria, formulas, and a planner, all based on prior financial document analysis and mapped to a given database schema. Your task is to use this structured extraction and the policy/calculation logic to construct a single, highly accurate SQL query answering the user's ratio question.

# Inputs
- You will be provided with an object: {{components}}
- This object contains the following:
  - `components`: All relevant financial formula components, with their associated sources (schema tables), criteria and risk (if any)
  - `formula`: The calculation or combination required among the components.
  - `planner`: Step-by-step reasoning/methodology for constructing the query and applying sources, components, and formula. Pay particular attention to the planner, following its detailed step-by-step instructions closely during SQL query construction.
- Database schema definitions are provided below.

# Output Instructions
- Using only the provided object (`components`, `source`, `criteria`, `risk (if any)`, `formula`, `planner`) and the supplied database schema, generate the final SQL query that answers the ratio calculation as described.
- Use the precise mapping of components to schema tables and strictly honor all detailed criteria and calculation logic described in the input object and planner.
- Ensure that any joins, filters, aggregations, or calculations respect the criteria and source information for each component.
- You must strongly consider and prioritize the use of the LIKE wildcard operator in your SQL queries whenever filters are involved, especially in scenarios where formatting or punctuation inconsistencies may exist in the database table values for those columns. The LIKE operator should be applied wherever necessary to robustly handle potential edge cases and ensure accurate filtering, except where an exact match is certain. Do not omit this step.
- Your output should be only the SQL query. Do not output any explanation, planner, or description—just the SQL code block.

# SQL Query Generation Steps
1. Parse each component and its associated source(s)/criteria strictly in accordance with the planner.
2. For components with different sources, use appropriate JOINs or UNIONs as needed, ensuring each step in the planner is followed exactly and in the sequence outlined by the planner and schema.
3. Apply all criteria to filtering, WHERE clauses, or CASE statements for risk weightings (as needed by formula/planner), precisely reflecting planner instructions.
4. Implement aggregation and formula calculation exactly as described (e.g., summing tiers, risk weighting assets, combining numerator/denominator conditions), strictly adhering to the methodology provided in the planner.
5. Output only the final SQL query, ready to execute.


# Reference Database Schema
- `gl_account_master(gl_acct_id, gl_account, branch, account_name, account_category, sub_category)`
- `gl_account_summary(gl_acct_id, acct_currency, ledger_balance, last_transaction_date)`
- `loan_portfolio(loan_id, branch, loan_type, loan_product, risk_weight_percentage, principal_amount, interest_rate, purpose, tenor_months, repayment_type, charge_collected, collateral_value, risk_class, outstanding_balance, accrued_interest, currency)`

# Output Format
- Output the final SQL query as a single code block, nothing else.
{{ctx.output_format}}
    "#
}

class Response{
    response_string string
}

function SqlResult(user_question:string, sql_result:string) -> Response{
    client CustomSonnet
    prompt #"
        You're an expert at briefing the sql query execution result to the user, according to
        what user has asked. Here's the user asked question: {{user_question}} and 
        here's the sql query result: {{sql_result}}

        {{ctx.output_format}}
    "#
}