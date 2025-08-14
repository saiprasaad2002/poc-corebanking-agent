from baml_client.type_builder import TypeBuilder
async def fetch_tools_and_description():
    tb = TypeBuilder()
    #mock function to simulate fetching tools from database
    allowed_tools = {
        "get_gl_balance": "To fetch the general ledger balance for a given account. The mandatory parameters are a gl account number. Any role can access this tool",
        "get_loan_balance": "To fetch the loan balance for a given account. The mandatory parameters are a loan account holder name. Any role can access this tool",
        "get_car_ratio": "To fetch the capital adequacy ratio for a bank. There are no specific mandatory parameters for this tool. The user's role must be adminstrators/senior level roles like CFO, Analyst, Propreitor(s),etc",
    }
    for tool_name, description in allowed_tools.items():
        tb.Tools.add_value(tool_name).description(description)
    
    #return the allowed tools with their descriptions
    return allowed_tools
