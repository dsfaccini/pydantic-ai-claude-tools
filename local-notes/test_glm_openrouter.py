"""Test script to verify GLM 4.6 vs 4.7 tool_choice behavior via OpenRouter.

Based on the snippet from https://github.com/pydantic/pydantic-ai/issues/3899

Testing various scenarios that might trigger the tool_choice error.
"""

import os
from dataclasses import dataclass

from pydantic import BaseModel
from pydantic_ai import Agent, RunContext
from pydantic_ai.models.openrouter import OpenRouterModel, OpenRouterModelSettings
from pydantic_ai.providers.openrouter import OpenRouterProvider

# Ensure API key is set
assert os.environ.get('OPENROUTER_API_KEY'), 'OPENROUTER_API_KEY must be set'


@dataclass
class MyDeps:
    user_id: str


class WeatherResult(BaseModel):
    city: str
    temperature: int
    description: str


def test_nested_agents(model_name: str) -> None:
    """Test with output_type=[function] pattern from issue #3899."""
    print(f'\n=== Testing {model_name} (nested agents) ===')

    response_agent: Agent[MyDeps, str] = Agent(
        f'openrouter:{model_name}',
        deps_type=MyDeps,
        output_type=str,
        system_prompt='Make human readable response.',
    )

    def get_humanized_response(context: RunContext[MyDeps], instructions: str) -> str:
        result = response_agent.run_sync(
            instructions,
            usage=context.usage,
            deps=context.deps,
        )
        return result.output

    orchestrator_agent: Agent[MyDeps, str] = Agent(
        f'openrouter:{model_name}',
        deps_type=MyDeps,
        output_type=[get_humanized_response],
    )

    try:
        result = orchestrator_agent.run_sync(
            'Tell the user about the weather in Paris today.',
            deps=MyDeps(user_id='test-user'),
        )
        print(f'Success! Output length: {len(result.output)} chars')
    except Exception as e:
        print(f'Error: {type(e).__name__}: {e}')


def test_structured_output(model_name: str) -> None:
    """Test with BaseModel output_type (tool_choice=required)."""
    print(f'\n=== Testing {model_name} (structured output) ===')

    agent: Agent[None, WeatherResult] = Agent(
        f'openrouter:{model_name}',
        output_type=WeatherResult,
    )

    try:
        result = agent.run_sync('Weather in Paris. Make up values.')
        print(f'Success! Output: {result.output}')
    except Exception as e:
        print(f'Error: {type(e).__name__}: {e}')


def test_with_provider_require_params(model_name: str) -> None:
    """Test with require_parameters=True provider option."""
    print(f'\n=== Testing {model_name} (require_parameters=True) ===')

    provider = OpenRouterProvider(api_key=os.environ['OPENROUTER_API_KEY'])
    model = OpenRouterModel(model_name, provider=provider)
    settings = OpenRouterModelSettings(
        openrouter_provider={'require_parameters': True}
    )

    agent: Agent[None, WeatherResult] = Agent(model, output_type=WeatherResult)

    try:
        result = agent.run_sync('Weather in Paris. Make up values.', model_settings=settings)
        print(f'Success! Output: {result.output}')
    except Exception as e:
        print(f'Error: {type(e).__name__}: {e}')


if __name__ == '__main__':
    models = ['z-ai/glm-4.6', 'z-ai/glm-4.7']

    for model in models:
        test_structured_output(model)

    for model in models:
        test_with_provider_require_params(model)

    for model in models:
        test_nested_agents(model)
