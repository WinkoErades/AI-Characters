#!/bin/bash
# create_persona.sh
#
# Author: Winko Erades van den Berg
# Date: February 12, 2025
# Revised: February 12, 2025
#
# Purpose: Script to create an Ollama persona from an existing LLM and a TavernAI character JSON file
#
# You would need to make this file executable by giving executable
# permissions:   eg.    chmod +x ./create_persona.sh

# Check if the required arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <base_llm> <tavernai_json> <new_llm>"
    exit 1
fi

# Set variables
LLM_BASE_MODEL="$1"  # Base LLM model (e.g., llama2, mistral)
TAVERN_JSON_FILE="$2" # Path to TavernAI JSON file
OLLAMA_MODEL_NAME="$3" # Desired Ollama model name

# Check if required tools are installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required. Please install it (e.g., apt-get install jq)."
    exit 1
fi

if ! command -v ollama &> /dev/null; then
    echo "Error: ollama is required. Please install it."
    exit 1
fi


# Get absolute path and properly handle spaces
TAVERN_JSON_FILE="$(realpath "$2")"

# Debugging: Print the path to check if it's correct
echo "Using JSON file: $TAVERN_JSON_FILE"

# Extract data from the TavernAI JSON file
CHAR_NAME=$(jq -r '.char_name // "Unnamed Character"' "$TAVERN_JSON_FILE" | tr '\n' '.' | sed 's/\.\+/./g')
PERSONALITY=$(jq -r '.personality // "No specific personality provided."' "$TAVERN_JSON_FILE" | tr '\n' '.' | sed 's/\.\+/./g')
DESCRIPTION=$(jq -r '.description // "No description available."' "$TAVERN_JSON_FILE" | tr '\n' '.' | sed 's/\.\+/./g')
WORLD_SCENARIO=$(jq -r '.world_scenario // "No world scenario set."' "$TAVERN_JSON_FILE" | tr '\n' '.' | sed 's/\.\+/./g')
CHAR_GREETING=$(jq -r '.char_greeting // "Hello, how can I assist you today?"' "$TAVERN_JSON_FILE" | tr '\n' '.' | sed 's/\.\+/./g')
EXAMPLE_MESSAGES=$(jq -r '.mes_example // "No example messages provided."' "$TAVERN_JSON_FILE" | tr '\n' '.' | sed 's/\.\+/./g')

# Debugging: Print extracted values
echo "Character Name: $CHAR_NAME"
echo "Personality: $PERSONALITY"
echo "Description: $DESCRIPTION"
echo "World Scenario: $WORLD_SCENARIO"
echo "Greeting: $CHAR_GREETING"
echo "Example Messages: $EXAMPLE_MESSAGES"

# Construct the prompt template with extracted data
PROMPT="You are $CHAR_NAME. Your personality summary: $PERSONALITY. Description: $DESCRIPTION. Current world scenario: $WORLD_SCENARIO. Greeting: $CHAR_GREETING. Example messages: $EXAMPLE_MESSAGES."

# Create the Ollama model
echo "Creating Ollama model '$OLLAMA_MODEL_NAME' based on '$LLM_BASE_MODEL'..."

# Create a modelfile
cat > Modelfile <<EOF
FROM $LLM_BASE_MODEL

SYSTEM """
$PROMPT
"""

LICENSE """
# Add license information if needed
"""
EOF

# Build the model
ollama create "$OLLAMA_MODEL_NAME" -f Modelfile

# Clean up the Modelfile (optional)
rm Modelfile

echo "Ollama persona '$OLLAMA_MODEL_NAME' created successfully!"
echo "You can now run it with: ollama run $OLLAMA_MODEL_NAME"

exit 0

