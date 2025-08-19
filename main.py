from fastapi import WebSocket, FastAPI,WebSocketDisconnect
import uvicorn
import uuid
from agent_state import AgentState
from tool_fetch import fetch_tools_and_description
from baml_client import b
from tools import get_gl_balance,get_loan_balance,get_car_ratio
from dotenv import load_dotenv
from md_document import return_markdown
from db import execute_query,get_sql_template
from sqlalchemy import text,bindparam
import datetime
load_dotenv()

app = FastAPI()


@app.websocket("/chat")
async def chat(websocket: WebSocket):
    await websocket.accept()
    tool_functions = {
        "get_gl_balance": get_gl_balance,
        "get_loan_balance": get_loan_balance,
        "get_car_ratio": get_car_ratio
    }
    while True:
        try:
            user_role = "Proprietor"
            user_question = await websocket.receive_text()
            user_id = uuid.uuid4()
            agent_state = AgentState(user_id)
            memory = agent_state.initialize_memory()
            memory['user_id'] = user_id
            memory['date_time'] = datetime.datetime.now().strftime("%d-%m-%Y %H:%M:%S")
            memory['user_question'] = user_question
            guardrail = b.InputGuardrail(user_question)
            memory['jail_break_attempt'] = guardrail.jail_break_attempt
            memory['jail_break_response'] = guardrail.response if guardrail.response else None
            if guardrail.jail_break_attempt:
                await websocket.send_text(guardrail.response)
            else:
                intent_check = b.CheckIntent(user_question)
                intent_validity = intent_check.valid
                memory['llm_intent_response'] = intent_validity
                if not intent_validity:
                    await websocket.send_text("Invalid intent. Please try again.")
                else:
                    route = b.DefineRoute(user_question)
                    memory['tool_call'] = route.tool
                    if route.tool.lower() == "ratios":
                        await websocket.send_text("Fetching ratios...")
                        document_path = "multipleratio2.docx"
                        markdown_document = return_markdown(document_path)
                        relevant_response = b.FetchResults(user_question,markdown_document)
                        components = {}
                        if relevant_response.valid:
                            for key, value in relevant_response.components.items():
                                components[key] = [
                                    {
                                        "source": val.source,
                                        "crieteria": val.crieteria,
                                        "risk": val.risk
                                    }
                                    for val in value
                                ]
                            response = {
                                "valid": relevant_response.valid,
                                "components": components,
                                "formula": relevant_response.formula,
                                "planner": relevant_response.planner,
                            }
                            sql_query_generator = b.SqlQueryGenerator(response)
                            sql_query = sql_query_generator.sql_query
                            memory['sql_query'] = sql_query
                            sql_result = execute_query(sql_query)
                            sql_result_brief = b.SqlResult(user_question,str(sql_result))
                            response_to_user = sql_result_brief.response_string
                            memory['response_to_user'] = response_to_user
                            await websocket.send_text(response_to_user)
                        else:
                            await websocket.send_text("No relevant response found. Please try again.")
                            memory['response_to_user']= "No relevant response found. Please try again."
                    elif route.tool.lower() == "gl_info":
                        await websocket.send_text("Fetching GL info...")
                        params = b.FetchGLParams(user_question)
                        if params.clarification:
                            await websocket.send_text(params.reason)
                            memory['clarification'] = params.reason
                        else:
                            parameters = {
                                "account_no_list":[f"%{account_no}%" for account_no in params.account_number],
                                "branch_list": [f"%{branch}%" for branch in params.branch] if params.branch else None
                            }
                            sql_template = get_sql_template()
                            query = text(sql_template).bindparams(bindparam("account_no_list"),bindparam("branch_list")).params(**parameters)
                            sql_result = execute_query(query)
                            sql_result_brief = b.SqlResult(user_question,str(sql_result))
                            response_to_user = sql_result_brief.response_string
                            memory['response_to_user'] = response_to_user
                            await websocket.send_text(response_to_user)
                    elif route.tool.lower() == "loan_info":
                        await websocket.send_text("Fetching loan info...")
                    elif route.tool.lower() == "invalid":
                        await websocket.send_text("Invalid. Please try again.")
            print(memory)
        except WebSocketDisconnect:
            await websocket.close()

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

        
