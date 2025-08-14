import uuid
from pydantic import BaseModel
from typing import List

class AgentState:
    def __init__(self, user_id: uuid.UUID):
        self.user_id = user_id
    
    def initialize_memory(self):
        memory = {}
        self.memory = memory
        return memory

    def get_memory(self):
        return self.memory


class AgentMemory(BaseModel):
    user_id: uuid.UUID
    user_question: str
    intent_check: bool
    tools_allowed: List[str]

