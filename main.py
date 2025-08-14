from fastapi import WebSocket, FastAPI,WebSocketDisconnect
import uvicorn
import uuid
from agent_state import AgentState
from tool_fetch import fetch_tools_and_description
from baml_client import b
from tools import get_gl_balance,get_loan_balance,get_car_ratio
from dotenv import load_dotenv
from md_document import return_markdown 
load_dotenv()

app = FastAPI()

#send a document to the websocket endpoint


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
            memory['user_question'] = user_question
            intent_check = b.CheckIntent(user_question)
            intent_validity = intent_check.valid
            if not intent_validity:
                await websocket.send_text("Invalid intent. Please try again.")
                memory['intent_check'] = False
                continue
            else:
                memory['intent_check'] = True
                # allowed_tools_and_description = await fetch_tools_and_description()
                # allowed_tools = list(allowed_tools_and_description.keys())
                # allowed_tools_description = list(allowed_tools_and_description.values())
                # memory['tools_allowed'] = allowed_tools
                # validation = b.ValidateToolCalling(user_question, allowed_tools, allowed_tools_description,user_role)
                # if not validation.valid:
                #     await websocket.send_text("Tool calling validation failed. Please try again.")
                #     memory['tool_validation'] = False
                #     continue
                # else:
                #     memory['tool_validation'] = True
                #     tool_names:list = validation.tool_name
                #     memory['tools_called'] = [tool_name for tool_name in tool_names]
                #     description:list = validation.description
                #     memory['tools_description'] = description
                document_path = "multipleratio2.docx"
                markdown_document = return_markdown(document_path)
                relevant_response = b.FetchResults(user_question,markdown_document)
                components = {}
                for key, value in relevant_response.components.items():
                    # value is a list of ComponentDetail objects
                    components[key] = [
                        {
                            "source": val.source,
                            "crieteria": val.crieteria,
                            "risk": val.risk
                        }
                        for val in value
                    ]

                response = {
                    "components": components,
                    "formula": relevant_response.formula,
                    "planner": relevant_response.planner,
                    "sql_template": relevant_response.sql_template
                }
                await websocket.send_json(response)
                    # clarity_check = b.Claritycheckfunction(user_question,tool_names,description,user_role)
                    # if not clarity_check.clarity:
                    #     reasoning = clarity_check.reasoning
                    #     await websocket.send_text(f"Clarity check failed: {reasoning}. Please clarify your question.")
                    #     memory['clarity_check'] = False
                    #     continue
                    # else:
                    #     memory['clarity_check'] = True
                    #     function_call = clarity_check.functioncall
                    #     for function in function_call:
                    #         tool_name = function.tool_name
                    #         parameters = function.parameters
                    #         call_tool = tool_functions.get(tool_name)
                    #         if parameters:
                    #             result = call_tool(*parameters)
                    #         else:
                    #             result = call_tool()
                    #         await websocket.send_text(f"Tool {tool_name} called with parameters: {parameters}, and the result is: {result}")             
        except WebSocketDisconnect:
            await websocket.close()

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

        
