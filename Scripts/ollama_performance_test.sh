#!/bin/bash

# Ollama Performance Testing Script
# Tests multiple Ollama instances with various models and prompts

set -euo pipefail

# Configuration
MAC_HOST="192.168.0.218"
PC_HOST="10.10.12.252"
OLLAMA_PORT="11434"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Models to test (adjust based on what you have available)
MODELS=(
    "qwen:latest"
    "tinyllama:latest"
    "llama3.1:8b"
    "gemma3:1b"
    "gemma3:4b"
    "llama2:latest"
)

# Test prompts for different scenarios (bash 3.2 compatible)
PROMPT_TYPES=("code" "reasoning" "math" "creative")
PROMPT_CODE="Write a Python function that calculates the Fibonacci sequence up to n terms using dynamic programming."
PROMPT_REASONING="Explain the concept of recursion and provide a real-world analogy that would help a beginner understand it."
PROMPT_MATH="Solve this problem step by step: If a train travels 120 km in 2 hours, then stops for 30 minutes, and continues for another 90 km at the same speed, what is the total time for the journey?"
PROMPT_CREATIVE="Write a haiku about artificial intelligence and cloud computing."

# Function to get prompt by type
get_prompt() {
    local type=$1
    case "$type" in
        code) echo "$PROMPT_CODE" ;;
        reasoning) echo "$PROMPT_REASONING" ;;
        math) echo "$PROMPT_MATH" ;;
        creative) echo "$PROMPT_CREATIVE" ;;
        *) echo "" ;;
    esac
}

# Results directory
RESULTS_DIR="./ollama_test_results"
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$RESULTS_DIR/results_$TIMESTAMP.csv"
LOG_FILE="$RESULTS_DIR/test_log_$TIMESTAMP.log"

# Initialize results file
echo "Timestamp,Host,Model,Prompt_Type,Response_Time_Sec,Total_Tokens,Tokens_Per_Sec,Success" > "$RESULTS_FILE"

# Function to test model availability
check_model() {
    local host=$1
    local model=$2

    echo -e "${CYAN}Checking if model $model is available on $host...${NC}" | tee -a "$LOG_FILE"

    response=$(curl -s "http://$host:$OLLAMA_PORT/api/tags" 2>/dev/null || echo "")

    if [[ -z "$response" ]]; then
        echo -e "${RED}Error: Cannot connect to Ollama at $host:$OLLAMA_PORT${NC}" | tee -a "$LOG_FILE"
        return 1
    fi

    if echo "$response" | grep -q "\"name\":\"$model\""; then
        echo -e "${GREEN}✓ Model $model found${NC}" | tee -a "$LOG_FILE"
        return 0
    else
        echo -e "${YELLOW}⚠ Model $model not found on $host${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to run a single test
run_test() {
    local host=$1
    local host_name=$2
    local model=$3
    local prompt_type=$4
    local prompt=$5

    echo -e "\n${BLUE}========================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}Testing: $host_name | $model | $prompt_type${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}========================================${NC}" | tee -a "$LOG_FILE"

    # Create request payload
    local request_payload=$(cat <<EOF
{
  "model": "$model",
  "prompt": "$prompt",
  "stream": false,
  "options": {
    "temperature": 0.7,
    "num_predict": 200
  }
}
EOF
)

    # Start timing
    local start_time=$(date +%s.%N)

    # Make the API call
    local response=$(curl -s -w "\n%{http_code}" \
        -X POST "http://$host:$OLLAMA_PORT/api/generate" \
        -H "Content-Type: application/json" \
        -d "$request_payload" \
        2>/dev/null)

    # End timing
    local end_time=$(date +%s.%N)

    # Extract HTTP status code (last line)
    local http_code=$(echo "$response" | tail -n 1)
    # Extract JSON response (all but last line) - BSD compatible
    local json_response=$(echo "$response" | sed '$d')

    # Calculate response time
    local response_time=$(echo "$end_time - $start_time" | bc)

    # Check if request was successful
    if [[ "$http_code" != "200" ]]; then
        echo -e "${RED}✗ Test failed with HTTP code: $http_code${NC}" | tee -a "$LOG_FILE"
        echo "$(date +%Y-%m-%d_%H:%M:%S),$host_name,$model,$prompt_type,$response_time,0,0,FAILED" >> "$RESULTS_FILE"
        return 1
    fi

    # Parse response for metrics using Python for reliable JSON parsing
    local metrics=$(echo "$json_response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    eval_count = data.get('eval_count', 0)
    eval_duration = data.get('eval_duration', 1)
    response_text = data.get('response', '')[:100].replace('\n', ' ').replace('|', '/')
    # Calculate tokens per second (eval_duration is in nanoseconds)
    tokens_per_sec = round(eval_count / (eval_duration / 1000000000), 2) if eval_duration > 0 and eval_count > 0 else 0
    print(f'{eval_count}|{eval_duration}|{tokens_per_sec}|{response_text}')
except:
    print('0|1|0|')
")

    local total_tokens=$(echo "$metrics" | cut -d'|' -f1)
    local eval_duration=$(echo "$metrics" | cut -d'|' -f2)
    local tokens_per_sec=$(echo "$metrics" | cut -d'|' -f3)
    local response_text=$(echo "$metrics" | cut -d'|' -f4)

    # Display results
    echo -e "${GREEN}✓ Test completed successfully${NC}" | tee -a "$LOG_FILE"
    echo -e "  Response time: ${YELLOW}${response_time}s${NC}" | tee -a "$LOG_FILE"
    echo -e "  Total tokens: ${YELLOW}${total_tokens}${NC}" | tee -a "$LOG_FILE"
    echo -e "  Tokens/sec: ${YELLOW}${tokens_per_sec}${NC}" | tee -a "$LOG_FILE"
    echo -e "  Response preview: ${response_text}..." | tee -a "$LOG_FILE"

    # Save to CSV
    echo "$(date +%Y-%m-%d_%H:%M:%S),$host_name,$model,$prompt_type,$response_time,$total_tokens,$tokens_per_sec,SUCCESS" >> "$RESULTS_FILE"

    return 0
}

# Function to check Ollama service availability
check_ollama_service() {
    local host=$1
    local host_name=$2

    echo -e "\n${CYAN}Checking Ollama service on $host_name ($host)...${NC}" | tee -a "$LOG_FILE"

    if curl -s -f "http://$host:$OLLAMA_PORT/api/tags" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama service is running on $host_name${NC}" | tee -a "$LOG_FILE"
        return 0
    else
        echo -e "${RED}✗ Cannot connect to Ollama service on $host_name${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Function to list available models on a host
list_available_models() {
    local host=$1
    local host_name=$2

    echo -e "\n${CYAN}Available models on $host_name:${NC}" | tee -a "$LOG_FILE"

    response=$(curl -s "http://$host:$OLLAMA_PORT/api/tags" 2>/dev/null || echo "{}")

    if [[ -n "$response" ]]; then
        echo "$response" | grep -o '"name":"[^"]*"' | sed 's/"name":"\(.*\)"/  - \1/' | tee -a "$LOG_FILE"
    else
        echo -e "${RED}  Could not retrieve model list${NC}" | tee -a "$LOG_FILE"
    fi
}

# Main test execution
main() {
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   Ollama Performance Testing Suite${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "Start time: $(date)" | tee -a "$LOG_FILE"
    echo -e "Results will be saved to: $RESULTS_FILE" | tee -a "$LOG_FILE"

    # Check both services
    mac_available=false
    pc_available=false

    if check_ollama_service "$MAC_HOST" "Mac"; then
        mac_available=true
        list_available_models "$MAC_HOST" "Mac"
    fi

    if check_ollama_service "$PC_HOST" "PC"; then
        pc_available=true
        list_available_models "$PC_HOST" "PC"
    fi

    if [[ "$mac_available" == false && "$pc_available" == false ]]; then
        echo -e "\n${RED}Error: No Ollama services are available. Exiting.${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Run tests
    total_tests=0
    successful_tests=0

    for model in "${MODELS[@]}"; do
        for prompt_type in "${PROMPT_TYPES[@]}"; do
            prompt=$(get_prompt "$prompt_type")

            # Test on Mac if available
            if [[ "$mac_available" == true ]]; then
                if check_model "$MAC_HOST" "$model"; then
                    ((total_tests++))
                    if run_test "$MAC_HOST" "Mac" "$model" "$prompt_type" "$prompt"; then
                        ((successful_tests++))
                    fi
                    sleep 2  # Brief pause between tests
                fi
            fi

            # Test on PC if available
            if [[ "$pc_available" == true ]]; then
                if check_model "$PC_HOST" "$model"; then
                    ((total_tests++))
                    if run_test "$PC_HOST" "PC" "$model" "$prompt_type" "$prompt"; then
                        ((successful_tests++))
                    fi
                    sleep 2  # Brief pause between tests
                fi
            fi
        done
    done

    # Summary
    echo -e "\n${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   Test Summary${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "Total tests: ${YELLOW}$total_tests${NC}" | tee -a "$LOG_FILE"
    echo -e "Successful: ${GREEN}$successful_tests${NC}" | tee -a "$LOG_FILE"
    echo -e "Failed: ${RED}$((total_tests - successful_tests))${NC}" | tee -a "$LOG_FILE"
    echo -e "End time: $(date)" | tee -a "$LOG_FILE"
    echo -e "\nResults saved to: ${CYAN}$RESULTS_FILE${NC}" | tee -a "$LOG_FILE"
    echo -e "Log saved to: ${CYAN}$LOG_FILE${NC}" | tee -a "$LOG_FILE"

    # Generate a quick analysis
    echo -e "\n${CYAN}Generating analysis...${NC}"

    if command -v column &> /dev/null; then
        echo -e "\n${BLUE}Top 5 fastest responses:${NC}"
        (head -n 1 "$RESULTS_FILE" && tail -n +2 "$RESULTS_FILE" | grep SUCCESS | sort -t',' -k5 -n | head -5) | column -t -s','

        echo -e "\n${BLUE}Top 5 highest tokens/sec:${NC}"
        (head -n 1 "$RESULTS_FILE" && tail -n +2 "$RESULTS_FILE" | grep SUCCESS | sort -t',' -k7 -rn | head -5) | column -t -s','
    fi
}

# Run main function
main "$@"
