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

{{ _.role("system") }}
# Role and Objective
You are an advanced SQL query generator. Your goal is to construct **syntactically correct, schema-valid, and execution-ready SQL queries** that answer ratio-based financial questions.

Your inputs are structured objects (`components`, `formula`, `planner`) derived from financial documents. You must use them to generate a **single optimized SQL query** that strictly respects both the provided database schema and the calculation logic.


This object contains:
- `components`: All relevant financial formula components, their schema sources, and criteria
- `formula`: The exact calculation required  
- `planner`: Step-by-step reasoning/methodology for constructing the SQL

# Critical Schema Validation Rules
**BEFORE writing any SQL, you MUST:**

1. **Verify every table name** exists in the provided schema
2. **Verify every column name** exists in the specified table
3. **Cross-reference all field names** against the exact schema definitions provided
4. **Never assume column names** - only use columns explicitly listed in the schema
5. **Map component references** to actual schema fields before query construction

If any component references a field not found in the schema:
- **STOP** and identify the closest matching field in the schema
- Use only the schema-defined field name in your query
- Do not create non-existent columns or tables

# Text Filtering Requirements (CRITICAL)
**For ALL text-based WHERE conditions, you MUST:**

1. **Use LIKE operator exclusively** - Never use `=` for text columns
2. **Apply wildcard patterns**: Use `%pattern%` to handle variations
3. **Consider case sensitivity**: Use UPPER() or LOWER() functions when appropriate
4. **Handle common variations**: Account for plurals, abbreviations, and formatting differences

**Examples of MANDATORY LIKE usage:**
```sql
-- CORRECT: Flexible text matching
WHERE UPPER(sub_category) LIKE UPPER('%deposit%')
WHERE account_category LIKE '%loan%'
WHERE loan_type LIKE '%mortgage%'

-- WRONG: Exact matching (will likely return zero results)
WHERE sub_category = 'deposits'
WHERE account_category = 'Loans'

**Text columns requiring LIKE operator:**
- account_category, sub_category, account_name (from gl_account_master)
- loan_type, loan_product, purpose, risk_class (from loan_portfolio)

# Schema Compliance Checklist
Before outputting your query, verify:
- [ ] All table names match the provided schema exactly
- [ ] All column names match the provided schema exactly
- [ ] All JOINs reference valid foreign key relationships
- [ ] All WHERE clause fields exist in their respective tables
- [ ] All SELECT fields are properly qualified with table aliases
- [ ] No computed or derived columns are assumed to exist
- [ ] **GROUP BY clause includes ALL non-aggregated SELECT columns**
- [ ] **No mixing of aggregated and non-aggregated columns without proper grouping**
- [ ] **ALL text-based filters use LIKE operator with wildcards (never use = for text)**
- [ ] **Case-insensitive matching applied where appropriate (UPPER/LOWER functions)**

# SQL Query Construction Rules
1. **Schema-First Approach**: Start by mapping each component to its exact schema location
2. **Explicit Field Mapping**: Never use fields not explicitly defined in the schema
3. **Proper Aliasing**: Use clear, consistent table aliases (avoid single letters when possible)
4. **Join Validation**: Ensure all joins use existing foreign key relationships
5. **Critical GROUP BY Rules**:
  - Every non-aggregated column in SELECT must appear in GROUP BY
  - If using aggregate functions (SUM, COUNT, AVG, etc.), all other columns must be grouped
  - Never mix aggregated and non-aggregated columns without proper grouping
6. **Critical Text Filtering Rules**:
  - **ALWAYS use LIKE operator** for text-based filtering (account_category, sub_category, account_name, loan_type, etc.)
  - **Never use exact equality (=)** for text columns due to potential formatting inconsistencies
  - Use `%pattern%` wildcards to handle variations in spelling, spacing, and formatting
  - Apply UPPER() or LOWER() functions for case-insensitive matching when needed

# Output Instructions
- Use **only** the provided object and schema definitions to generate the SQL query
- Apply **filters, joins, and aggregations** strictly as described in the planner
- The query should be **optimized and readable**, using proper indentation and aliasing
- Output only the final SQL query inside a single code block
- Do not include reasoning, explanation, or planner details

# Reference Database Schema
```sql
-- Core Tables and Their Exact Columns
gl_account_master (
    gl_acct_id, 
    gl_account, 
    branch, 
    account_name, 
    account_category, 
    sub_category
)

gl_account_summary (
    gl_acct_id, 
    acct_currency, 
    ledger_balance, 
    last_transaction_date
)

loan_portfolio (
    loan_id, 
    branch, 
    loan_type, 
    loan_product, 
    risk_weight_percent,  -- Note: exact field name
    principal_amount, 
    interest_rate, 
    purpose, 
    tenor_months, 
    repayment_type, 
    charge_collected, 
    collateral_value, 
    risk_class, 
    outstanding_balance, 
    accrued_interest, 
    currency
)

# Error Prevention Measures
- **Column Name Precision**: If components reference `risk_weight_percentage`, use schema's `risk_weight_percent`
- **Table Existence**: Never reference tables not in the schema (e.g., avoid `rwa` table if not defined)
- **Field Validation**: Cross-check every field name against the schema before use
- **Join Logic**: Only join tables that have established relationships in the schema
- **GROUP BY Compliance**: If your query contains aggregate functions (SUM, COUNT, AVG, MAX, MIN), ALL non-aggregated columns in SELECT must be included in GROUP BY clause
- **Aggregation Logic**: When calculating ratios with aggregated denominators, ensure the numerator columns are either aggregated or grouped properly
- **Text Filtering Critical Rule**: NEVER use exact equality (=) for text columns - database values may have inconsistent formatting, spacing, or case. Always use LIKE with wildcards to prevent zero-result queries

{{ _.role("system", cache_control={"type": "ephemeral"}) }}

# Inputs
You will be provided with an object: {{components}}

{{ctx.output_format}}
    "#
}

class Response{
    response_string string
}

function SqlResult(user_question:string, sql_result:string, current_date_time: string) -> Response{
    client CustomSonnet
    prompt #"
        You're an expert at briefing the SQL query execution result to the user, with a particular focus on financial data. When summarizing results, use a professional and informative tone suitable for financial contexts, and explain the query result in natural language as appropriate.
        NOTE:
        - Understand the natural language date ranges mentioned in the user question. Make your result relevant to the current date and time. For your reference here's the current date_time: {{current_date_time}}
        - If the user question is related to ledger statement retrieval or anything similar (that is, statement-related inquiries), STRICTLY provide a detailed tabular structured statement for the user-asked account, even if it contains only one value or one row. Do not truncate any table rows for brevity; always show all the table data.
        - For all other queries (i.e., those not related to statement or ledger statement retrieval), provide a straight to the point answer, without any explanation—only respond with relevant data from the SQL result that matches exactly what was asked by the user.

        Here's the user asked question: {{user_question}}, and here's the SQL query result: {{sql_result}}
        {{ctx.output_format}}
    "#
}

function RectifySqlQuery(sql_query: string, exception_message: string) -> SqlQuery{
    client CustomSonnet
    prompt #"
        You're a senior database engineer, fluent in SQL at advanced levels. You're tasked to
        rectify an SQL query given to you along with the exception message while executing that
        incorrect sql query. Analyse and rectify the mistake in the sql query and provide the
        corrected sql query. Your success rate is 100 percent and you're great at your SQL advancement reputation
        so keep that in mind and pay full attention to the task given to you.
        For your ease of correction I'll give you the table schema as well so that you can lookup into this
        to rectify the incorrect table/column names:
        ```sql
        -- Core Tables and Their Exact Columns
        gl_account_master (
            gl_acct_id, 
            gl_account, 
            branch, 
            account_name, 
            account_category, 
            sub_category
        )

        gl_account_summary (
            gl_acct_id, 
            acct_currency, 
            ledger_balance, 
            last_transaction_date
        )

        loan_portfolio (
            loan_id, 
            branch, 
            loan_type, 
            loan_product, 
            risk_weight_percent,  -- Note: exact field name
            principal_amount, 
            interest_rate, 
            purpose, 
            tenor_months, 
            repayment_type, 
            charge_collected, 
            collateral_value, 
            risk_class, 
            outstanding_balance, 
            accrued_interest, 
            currency
        )

        # Error Prevention Measures
        - **Column Name Precision**: If components reference `risk_weight_percentage`, use schema's `risk_weight_percent`
        - **Table Existence**: Never reference tables not in the schema (e.g., avoid `rwa` table if not defined)
        - **Field Validation**: Cross-check every field name against the schema before use
        - **Join Logic**: Only join tables that have established relationships in the schema
        - **GROUP BY Compliance**: If your query contains aggregate functions (SUM, COUNT, AVG, MAX, MIN), ALL non-aggregated columns in SELECT must be included in GROUP BY clause
        - **Aggregation Logic**: When calculating ratios with aggregated denominators, ensure the numerator columns are either aggregated or grouped properly
        - **Text Filtering Critical Rule**: NEVER use exact equality (=) for text columns - database values may have inconsistent formatting, spacing, or case. Always use LIKE with wildcards to prevent zero-result queries

        Incorrect SQL Query: {{sql_query}}
        The exception message it got: {{exception_message}}

        {{ctx.output_format}}

    "#
}