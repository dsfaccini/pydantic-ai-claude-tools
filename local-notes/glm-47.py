from typing import Literal

from pydantic import BaseModel

from pydantic_ai import Agent, RunContext, __version__
from pydantic_ai.models.openai import OpenAIResponsesModel
from pydantic_ai.models.openrouter import OpenRouterModel
from pydantic_ai.providers.openrouter import OpenRouterProvider

print(__version__)

chatgpt_model = OpenRouterModel(
    model_name='openai/gpt-5.2-chat',
    provider=OpenRouterProvider(),
)


glm_model = OpenAIResponsesModel(
    model_name='z-ai/glm-4.7',
    provider=OpenRouterProvider(),
)

response_agent = Agent()


class SkippedOutputData(BaseModel):
    """Use this output to indicate that user does not need to be answered in this turn."""


class Conversation(BaseModel):
    id: int


def get_humanized_response(
    context: RunContext[Conversation],
    instructions: str,
    language_code: Literal['en', 'es'],
) -> str:
    """Generate a human-readable response for conversation based on instructions and language code.

    Args:
        instructions: Instructions for response. It should be grounded and precise. Should contain commands what to write, when making this response.
        language_code: Language code for response.
    """
    messages = context.messages[:-1]
    sending_instructions = f'Instructions: {instructions}\n\n---\nLanguage: {language_code}'
    result = response_agent.run_sync(
        sending_instructions,
        model=chatgpt_model,
        message_history=messages,
        usage=context.usage,
    )
    return result.output


customer_conversation_agent = Agent(
    output_type=[get_humanized_response, SkippedOutputData],
    deps_type=Conversation,
)


result = customer_conversation_agent.run_sync(
    user_prompt=['Hello'],
    model=glm_model,
    deps=Conversation(id=5),
)

print(result)
