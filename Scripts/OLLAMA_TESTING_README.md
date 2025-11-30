# Ollama Performance Testing Suite

## Overview
This suite tests performance across multiple Ollama instances with different models and prompt types.

## Test Configuration

### Systems
- **Mac**: 192.168.0.218 (64GB unified memory)
- **PC**: 10.10.12.252 (RTX 3050 Ti, 4GB VRAM)
- **Port**: 11434 (Ollama default)

### Models Tested
- qwen:1.5b
- qwen:4b
- gemma:2b
- gemma:7b
- qwen2.5-coder:1.5b

### Test Prompts
1. **Code Generation**: Tests coding assistance capabilities
2. **Reasoning**: Tests logical reasoning and explanation
3. **Math**: Tests mathematical problem-solving
4. **Creative**: Tests creative writing (haiku generation)

## Usage

### 1. First-time Setup (Pull Models)
```bash
cd Scripts/
./setup_test_models.sh
```

This will pull all required models on both systems. It may take 10-30 minutes depending on your network speed.

### 2. Run Performance Tests
```bash
./ollama_performance_test.sh
```

### 3. View Results
Results are saved in `./ollama_test_results/`:
- `results_TIMESTAMP.csv` - Structured data for analysis
- `test_log_TIMESTAMP.log` - Detailed execution log

## Metrics Collected
- **Response Time**: Total time for generation (seconds)
- **Total Tokens**: Number of tokens generated
- **Tokens/Second**: Generation speed
- **Success Rate**: Percentage of successful completions

## Customization

### Modify Hosts
Edit the script variables:
```bash
MAC_HOST="192.168.0.218"
PC_HOST="10.10.12.252"
```

### Add/Remove Models
Edit the `MODELS` array in `ollama_performance_test.sh`:
```bash
MODELS=(
    "qwen:1.5b"
    "your-model:tag"
)
```

### Customize Prompts
Edit the `PROMPTS` associative array:
```bash
PROMPTS[your_category]="Your test prompt here"
```

### Adjust Token Limit
Modify the `num_predict` option in the script (default: 200):
```bash
"options": {
    "temperature": 0.7,
    "num_predict": 200
}
```

## Analyzing Results

### Using spreadsheet software
Open the CSV file in Excel, Google Sheets, or LibreOffice to create charts and pivot tables.

### Using command-line tools
```bash
# View results
cat ollama_test_results/results_*.csv | column -t -s','

# Get average response time per model
awk -F',' 'NR>1 && $8=="SUCCESS" {sum[$3]+=$5; count[$3]++}
    END {for (model in sum) print model": "sum[model]/count[model]"s"}' \
    ollama_test_results/results_*.csv

# Get average tokens/sec per host
awk -F',' 'NR>1 && $8=="SUCCESS" {sum[$2]+=$7; count[$2]++}
    END {for (host in sum) print host": "sum[host]/count[host]" tok/s"}' \
    ollama_test_results/results_*.csv
```

## Troubleshooting

### Cannot connect to Ollama service
1. Verify Ollama is running on both systems
2. Check firewall settings
3. Test connectivity: `curl http://192.168.0.218:11434/api/tags`

### Model not found
1. Run `./setup_test_models.sh` to pull models
2. Or manually: `ollama pull model:tag` on each system

### Slow performance
- Reduce `num_predict` in the script
- Test fewer models
- Increase sleep time between tests

## Notes
- The script pauses 2 seconds between tests to avoid overloading systems
- Failed tests are logged but don't stop execution
- All tests use temperature 0.7 for consistency
- Results include both successful and failed attempts
