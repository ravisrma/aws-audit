#!/bin/bash
START_TIME=$(date +%s)
LOG_FILE="audit_aws_$(date +%Y%m%d_%H%M%S).log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Colorful ASCII Art Banner (use printf for color)
printf "%b" "$CYAN"
printf "%s\n" "     _ __     __ ___     _            __ _  _ " \
"    /_\\ \    / // __|   /_\\  _  _  __| |(_)| |_ " \
"   / _ \\ \/\/ / \__ \  / _ \\| || |/ _' || ||  _|" \
"  /_/ \_\\_/\_/  |___/ /_/ \_\\_,_|\__,_||_| \__|"
printf "%b\n" "$NC"

echo -e "${YELLOW}📄 Log file: $LOG_FILE${NC}"

# Optional: log to file
exec > >(tee "$LOG_FILE") 2>&1

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

echo -e "${YELLOW}🧾 AWS Cost Audit Started on $(date +'%d-%b-%Y %H:%M:%S')${NC}"
echo -e "${BLUE}👤 Account: $ACCOUNT_ID | 📍 Region: $REGION${NC}"
echo -e "${CYAN}==============================${NC}"

# Pre-flight checks for required tools
REQUIRED_CMDS=(aws jq)
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}Required tool '$cmd' is not installed. Exiting.${NC}"
        exit 1
    fi
done

# Spinner function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\\'
    while [ -d /proc/$pid ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%$temp}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Section divider
divider() {
    echo -e "${CYAN}----------------------------------------------${NC}"
}

# Sound function (if supported)
sound_success() {
    command -v play &>/dev/null && play -nq -t alsa synth 0.1 sine 880 &>/dev/null || true
}
sound_fail() {
    command -v play &>/dev/null && play -nq -t alsa synth 0.1 sine 220 &>/dev/null || true
}

# AWS Console Links
console_link() {
    case "$1" in
        "Budget Alerts") echo "https://console.aws.amazon.com/billing/home#/budgets" ;;
        "Untagged Resources") echo "https://console.aws.amazon.com/resource-groups/tag-editor" ;;
        "Idle EC2 Resources") echo "https://console.aws.amazon.com/ec2/v2/home" ;;
        "S3 Lifecycle Policies") echo "https://console.aws.amazon.com/s3/home" ;;
        "Old RDS Snapshots") echo "https://console.aws.amazon.com/rds/home" ;;
        "Forgotten EBS Volumes") echo "https://console.aws.amazon.com/ec2/v2/home#Volumes:" ;;
        "Data Transfer Risks") echo "https://console.aws.amazon.com/vpc/home" ;;
        "On-Demand EC2 Instances") echo "https://console.aws.amazon.com/ec2/v2/home" ;;
        "Idle Load Balancers") echo "https://console.aws.amazon.com/ec2/v2/home#LoadBalancers:" ;;
        *) echo "https://console.aws.amazon.com/" ;;
    esac
}

# Explicit mapping from check names to script filenames
declare -A script_map=(
    ["Budget Alerts"]="check_budgets.sh"
    ["Untagged Resources"]="check_untagged_resources.sh"
    ["Idle EC2 Resources"]="check_idle_ec2.sh"
    ["S3 Lifecycle Policies"]="check_s3_lifecycle.sh"
    ["Old RDS Snapshots"]="check_old_rds_snapshots.sh"
    ["Forgotten EBS Volumes"]="check_forgotten_ebs.sh"
    ["Data Transfer Risks"]="check_data_transfer_risks.sh"
    ["On-Demand EC2 Instances"]="check_on_demand_instances.sh"
    ["Idle Load Balancers"]="check_idle_load_balancers.sh"
)

# Run individual checks

declare -i issues=0
declare -A results
pass_count=0
fail_count=0
checks=(
    "Budget Alerts"
    "Untagged Resources"
    "Idle EC2 Resources"
    "S3 Lifecycle Policies"
    "Old RDS Snapshots"
    "Forgotten EBS Volumes"
    "Data Transfer Risks"
    "On-Demand EC2 Instances"
    "Idle Load Balancers"
)

for check in "${checks[@]}"; do
    divider
    echo -e "\n🔎 --- ${check} Check ---"
    script_name="./${script_map[$check]}"
    (
        $script_name
    ) &
    pid=$!
    spinner $pid
    wait $pid
    status=$?
    if [ $status -eq 0 ]; then
        results["$check"]="${GREEN}✅ PASS${NC}"
        ((pass_count++))
        sound_success
    else
        results["$check"]="${RED}❌ FAIL${NC}"
        ((fail_count++))
        issues+=1
        sound_fail
        echo -e "${YELLOW}🔗 AWS Console: $(console_link "$check")${NC}"
    fi

done

divider
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
AUDIT_SCORE=$((pass_count * 100 / (${#checks[@]})))

if (( issues > 0 )); then
    echo -e "\n${RED}❌ Audit completed with $issues issue(s) detected. Please review the log file: $LOG_FILE${NC}"
    # Log file preview
    echo -e "\n${YELLOW}📝 Last 10 lines of log:${NC}"
    tail -n 10 "$LOG_FILE"
    echo -e "\n${RED}📉 Audit Score: ${AUDIT_SCORE}%${NC}"
    echo -e "\n${RED}❌${NC}"
else
    echo -e "\n${GREEN}✅ AWS Audit Completed: No issues detected.${NC}"
    echo -e "\n${GREEN}🏆 Audit Score: 100%${NC}"
    echo -e "\n${GREEN}✅${NC}"
fi

echo -e "\n${CYAN}⏱️ Audit runtime: ${ELAPSED} seconds${NC}"

# Random AWS cost-saving tip
TIPS=(
    "🧠 Use AWS Compute Optimizer to right-size EC2 instances."
    "🗑️ Enable S3 lifecycle policies to automatically delete old objects."
    "💸 Purchase Reserved Instances or Savings Plans for predictable workloads."
    "🧹 Delete unused EBS volumes and snapshots to save storage costs."
    "🚦 Review and remove idle load balancers to avoid unnecessary charges."
    "🏷️ Tag resources for better cost allocation and management."
    "🔄 Monitor data transfer costs and use VPC endpoints where possible."
)
TIP_INDEX=$((RANDOM % ${#TIPS[@]}))
echo -e "\n${YELLOW}💡 Cost-Saving Tip: ${TIPS[$TIP_INDEX]}${NC}"