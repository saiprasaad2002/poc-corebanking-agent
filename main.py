from fastapi import WebSocket, FastAPI,WebSocketDisconnect
import uvicorn
import uuid
from agent_state import AgentState
from tool_fetch import fetch_tools_and_description
from baml_client.async_client import b
from tools import get_gl_balance,get_loan_balance,get_car_ratio
from dotenv import load_dotenv
from md_document import return_markdown
from db import execute_query,get_sql_template
from sqlalchemy import text,bindparam
import datetime
import asyncio

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
            current_date_time = datetime.datetime.now().strftime("%d-%m-%Y %H:%M:%S")
            memory['user_id'] = user_id
            memory['date_time'] = current_date_time
            memory['user_question'] = user_question
            if user_question.lower() in ["exit", "bye"]:
                await websocket.send_text("Goodbye! Have a nice day.")
                await websocket.close()
            else:
                guardrail = await b.InputGuardrail(user_question)
                memory['jail_break_attempt'] = guardrail.jail_break_attempt
                memory['jail_break_response'] = guardrail.response if guardrail.response else None
                if guardrail.jail_break_attempt:
                    await websocket.send_text(guardrail.response)
                else:
                    intent_check = await b.CheckIntent(user_question)
                    intent_validity = intent_check.valid
                    memory['llm_intent_response'] = intent_validity
                    if not intent_validity:
                        await websocket.send_text("Invalid intent. Please try again.")
                    else:
                        route = await b.DefineRoute(user_question)
                        memory['tool_call'] = route.tool
                        if route.tool.lower() == "ratios":
                            await websocket.send_text("Calculating your bank's financial fitness! 💪📈")
                            document_path = "multipleratio2.docx"
                            markdown_document = return_markdown(document_path)
                            await websocket.send_text("Deep-diving into the sacred texts of your bank's policies 🏛️📖")
                            relevant_response = await b.FetchResults(user_question,markdown_document)
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
                                sql_query_generator = await b.SqlQueryGenerator(response)
                                sql_query = sql_query_generator.sql_query
                                memory['sql_query'] = sql_query

                                await websocket.send_text("The query just hit the gym, flexing back in a sec 💪📊.")
                                await asyncio.sleep(0)

                                try:
                                    sql_result = execute_query(sql_query)
                                except Exception as e1:
                                    await websocket.send_text("Sending the query on a coffee run… results coming right up ☕🚀")
                                    await asyncio.sleep(0)
                                    rectify_sql = await b.RectifySqlQuery(sql_query, str(e1))
                                    correct_sql_query = rectify_sql.sql_query

                                    try:
                                        sql_result = execute_query(correct_sql_query)
                                    except Exception as e2:
                                        await websocket.send_text("Spinning up some data magic tricks… stay tuned 🎩✨")
                                        await asyncio.sleep(0)
                                        rectify_sql = await b.RectifySqlQuery(correct_sql_query, str(e2))
                                        correct_sql_query = rectify_sql.sql_query

                                        try:
                                            sql_result = execute_query(correct_sql_query)
                                        except Exception as e3:
                                            error_message = f"Sorry, the query couldn't be executed after multiple retries 😞\nError: {str(e3)}"
                                            await websocket.send_text(error_message)
                                            sql_result = error_message

                                sql_result_brief = await b.SqlResult(user_question, str(sql_result), str(current_date_time))
                                response_to_user = sql_result_brief.response_string
                                memory['response_to_user'] = response_to_user

                                await websocket.send_text("Double-checking the final detail… almost there 👀✅")
                                await asyncio.sleep(0)

                                output_guardrails = await b.OutputGuardrail(response_to_user)
                                formatted_response = output_guardrails.formatted_message
                                memory['formatted_response'] = formatted_response

                                await websocket.send_text(formatted_response)
                            else:
                                await websocket.send_text("No relevant response found. Please try again.")
                                memory['response_to_user']= "No relevant response found. Please try again."
                        elif route.tool.lower() == "gl_info":
                            await websocket.send_text("Scanning the ledger for you! 👀📈")
                            params = await b.FetchGLParams(user_question)
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
                                await websocket.send_text("Crunching some numbers! 🔥")
                                sql_result = execute_query(query)
                                sql_result_brief = await b.SqlResult(user_question,str(sql_result),str(current_date_time))
                                response_to_user = sql_result_brief.response_string
                                memory['response_to_user'] = response_to_user
                                await websocket.send_text("Ah, the classic 'let me rephrase that' moment! 😄")
                                output_guardrails = await b.OutputGuardrail(response_to_user)
                                formatted_response = output_guardrails.formatted_message
                                memory['formatted_response'] = formatted_response
                                await websocket.send_text(formatted_response)
                        elif route.tool.lower() == "loan_info":
                            await websocket.send_text("Fetching loan info...")
                        elif route.tool.lower() == "invalid":
                            await websocket.send_text("Invalid. Please try again.")
            print(memory)
        except WebSocketDisconnect:
            await websocket.close()

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

        
