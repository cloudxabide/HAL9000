#!/bin/bash

# Ollama Performance Results Analyzer
# Generates summary reports from test results

RESULTS_DIR="./ollama_test_results"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if results directory exists
if [[ ! -d "$RESULTS_DIR" ]]; then
    echo -e "${YELLOW}No results directory found. Run ./ollama_performance_test.sh first.${NC}"
    exit 1
fi

# Find the most recent results file
LATEST_RESULT=$(ls -t "$RESULTS_DIR"/results_*.csv 2>/dev/null | head -1)

if [[ -z "$LATEST_RESULT" ]]; then
    echo -e "${YELLOW}No results files found.${NC}"
    exit 1
fi

echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Ollama Performance Analysis${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "Analyzing: ${CYAN}$(basename "$LATEST_RESULT")${NC}\n"

# Overall Statistics
echo -e "${BLUE}Overall Statistics:${NC}"
total_tests=$(tail -n +2 "$LATEST_RESULT" | wc -l | tr -d ' ')
successful_tests=$(tail -n +2 "$LATEST_RESULT" | grep -c SUCCESS)
failed_tests=$((total_tests - successful_tests))

echo "  Total tests: $total_tests"
echo "  Successful: $successful_tests"
echo "  Failed: $failed_tests"

if [[ $successful_tests -eq 0 ]]; then
    echo -e "\n${YELLOW}No successful tests to analyze.${NC}"
    exit 0
fi

# Performance by Host
echo -e "\n${BLUE}Performance by Host:${NC}"
awk -F',' 'NR>1 && $8=="SUCCESS" {
    sum_time[$2]+=$5;
    sum_tokens[$2]+=$6;
    sum_tps[$2]+=$7;
    count[$2]++;
}
END {
    for (host in count) {
        printf("  %s:\n", host);
        printf("    Avg Response Time: %.2fs\n", sum_time[host]/count[host]);
        printf("    Avg Tokens: %.0f\n", sum_tokens[host]/count[host]);
        printf("    Avg Tokens/sec: %.2f\n", sum_tps[host]/count[host]);
        printf("    Tests: %d\n", count[host]);
    }
}' "$LATEST_RESULT"

# Performance by Model
echo -e "\n${BLUE}Performance by Model:${NC}"
awk -F',' 'NR>1 && $8=="SUCCESS" {
    sum_time[$3]+=$5;
    sum_tps[$3]+=$7;
    count[$3]++;
}
END {
    for (model in count) {
        printf("  %s:\n", model);
        printf("    Avg Response Time: %.2fs\n", sum_time[model]/count[model]);
        printf("    Avg Tokens/sec: %.2f\n", sum_tps[model]/count[model]);
        printf("    Tests: %d\n", count[model]);
    }
}' "$LATEST_RESULT" | sort

# Performance by Prompt Type
echo -e "\n${BLUE}Performance by Prompt Type:${NC}"
awk -F',' 'NR>1 && $8=="SUCCESS" {
    sum_time[$4]+=$5;
    sum_tps[$4]+=$7;
    count[$4]++;
}
END {
    for (prompt in count) {
        printf("  %s:\n", prompt);
        printf("    Avg Response Time: %.2fs\n", sum_time[prompt]/count[prompt]);
        printf("    Avg Tokens/sec: %.2f\n", sum_tps[prompt]/count[prompt]);
        printf("    Tests: %d\n", count[prompt]);
    }
}' "$LATEST_RESULT"

# Fastest and Slowest Tests
echo -e "\n${BLUE}Top 5 Fastest Tests:${NC}"
(head -n 1 "$LATEST_RESULT" && tail -n +2 "$LATEST_RESULT" | grep SUCCESS | sort -t',' -k5 -n | head -5) | \
awk -F',' 'NR==1 {printf("  %-8s %-15s %-20s %s\n", "Time", "Host", "Model", "Prompt");
                  printf("  %s\n", "────────────────────────────────────────────────────────");
                  next}
            {printf("  %-8.2fs %-15s %-20s %s\n", $5, $2, $3, $4)}'

echo -e "\n${BLUE}Top 5 Highest Tokens/sec:${NC}"
(head -n 1 "$LATEST_RESULT" && tail -n +2 "$LATEST_RESULT" | grep SUCCESS | sort -t',' -k7 -rn | head -5) | \
awk -F',' 'NR==1 {printf("  %-10s %-15s %-20s %s\n", "Tok/sec", "Host", "Model", "Prompt");
                  printf("  %s\n", "────────────────────────────────────────────────────────");
                  next}
            {printf("  %-10.2f %-15s %-20s %s\n", $7, $2, $3, $4)}'

# Mac vs PC Comparison (if both tested)
mac_count=$(tail -n +2 "$LATEST_RESULT" | grep SUCCESS | grep -c "Mac")
pc_count=$(tail -n +2 "$LATEST_RESULT" | grep SUCCESS | grep -c "PC")

if [[ $mac_count -gt 0 && $pc_count -gt 0 ]]; then
    echo -e "\n${BLUE}Mac vs PC Head-to-Head:${NC}"

    mac_avg_tps=$(awk -F',' '$2=="Mac" && $8=="SUCCESS" {sum+=$7; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}' "$LATEST_RESULT")
    pc_avg_tps=$(awk -F',' '$2=="PC" && $8=="SUCCESS" {sum+=$7; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}' "$LATEST_RESULT")

    mac_avg_time=$(awk -F',' '$2=="Mac" && $8=="SUCCESS" {sum+=$5; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}' "$LATEST_RESULT")
    pc_avg_time=$(awk -F',' '$2=="PC" && $8=="SUCCESS" {sum+=$5; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}' "$LATEST_RESULT")

    echo "  Tokens/sec:"
    echo "    Mac: $mac_avg_tps tok/s"
    echo "    PC:  $pc_avg_tps tok/s"

    # Determine winner
    if (( $(echo "$mac_avg_tps > $pc_avg_tps" | bc -l) )); then
        speedup=$(echo "scale=2; ($mac_avg_tps - $pc_avg_tps) / $pc_avg_tps * 100" | bc)
        echo -e "    ${GREEN}Winner: Mac (${speedup}% faster)${NC}"
    elif (( $(echo "$pc_avg_tps > $mac_avg_tps" | bc -l) )); then
        speedup=$(echo "scale=2; ($pc_avg_tps - $mac_avg_tps) / $mac_avg_tps * 100" | bc)
        echo -e "    ${GREEN}Winner: PC (${speedup}% faster)${NC}"
    else
        echo "    Tie!"
    fi

    echo ""
    echo "  Response Time:"
    echo "    Mac: ${mac_avg_time}s"
    echo "    PC:  ${pc_avg_time}s"
fi

# Recommendations
echo -e "\n${CYAN}Recommendations:${NC}"

# Find best model for each system
mac_best=$(awk -F',' '$2=="Mac" && $8=="SUCCESS" {tps[$3]+=$7; count[$3]++}
    END {max=0; best="";
         for(m in tps) {avg=tps[m]/count[m]; if(avg>max) {max=avg; best=m}}
         print best}' "$LATEST_RESULT")

pc_best=$(awk -F',' '$2=="PC" && $8=="SUCCESS" {tps[$3]+=$7; count[$3]++}
    END {max=0; best="";
         for(m in tps) {avg=tps[m]/count[m]; if(avg>max) {max=avg; best=m}}
         print best}' "$LATEST_RESULT")

if [[ -n "$mac_best" ]]; then
    echo "  • Best model for Mac: $mac_best"
fi

if [[ -n "$pc_best" ]]; then
    echo "  • Best model for PC: $pc_best"
fi

# Check for failures
if [[ $failed_tests -gt 0 ]]; then
    echo "  • Review failed tests in the log file"
fi

echo -e "\n${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "Full results: ${CYAN}$LATEST_RESULT${NC}"
