"""Test script to demonstrate Logfire metadata tracking with PydanticAI.

This shows how to use the new `metadata` parameter to add custom attributes
like conversation_id and user_id to agent spans.
"""

import asyncio
import os

assert os.environ["LOGFIRE_TOKEN"]

import logfire

logfire.configure()
logfire.instrument_pydantic_ai()

from pydantic_ai import Agent

# Create an agent with a name (this is already tracked automatically)
agent = Agent(
    "openai:gpt-4o-mini",
    name="support_agent",
    instructions="Be concise, reply with one sentence.",
)


async def main():
    # Run with custom metadata - this will appear in Logfire spans
    result = await agent.run(
        "What is 2 + 2?",
        metadata={
            "conversation_id": "conv_12345",
            "user_id": "user_abc",
            "session_id": "sess_xyz",
        },
    )
    print(f"Result: {result.output}")
    print(f"Metadata: {result.metadata}")

    # You can also use dynamic metadata via a callable
    result2 = await agent.run(
        "What is 3 + 3?",
        metadata=lambda ctx: {
            "conversation_id": "conv_67890",
            "user_id": "user_def",
            "run_number": 2,
        },
    )
    print(f"Result 2: {result2.output}")
    print(f"Metadata 2: {result2.metadata}")


if __name__ == "__main__":
    asyncio.run(main())
