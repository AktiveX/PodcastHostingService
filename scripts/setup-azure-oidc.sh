#!/bin/bash

# Azure OIDC Setup Script for GitHub Actions
# This script automates the setup of OIDC authentication between GitHub Actions and Azure

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Default values
APP_NAME="podcast-hosting-github-oidc"
WHATIF=false

# Function to display usage
usage() {
    echo "Usage: $0 -o <github-org> -r <github-repo> [-n <app-name>] [-w]"
    echo "  -o, --org        GitHub organization/username (required)"
    echo "  -r, --repo       GitHub repository name (required)"
    echo "  -n, --name       App registration name (default: $APP_NAME)"
    echo "  -w, --whatif     Show what would be done without making changes"
    echo "  -h, --help       Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--org)
            GITHUB_ORG="$2"
            shift 2
            ;;
        -r|--repo)
            GITHUB_REPO="$2"
            shift 2
            ;;
        -n|--name)
            APP_NAME="$2"
            shift 2
            ;;
        -w|--whatif)
            WHATIF=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$GITHUB_ORG" || -z "$GITHUB_REPO" ]]; then
    echo -e "${RED}Error: GitHub organization and repository are required${NC}"
    usage
fi

echo -e "${CYAN}=== Azure OIDC Setup for GitHub Actions ===${NC}"
echo -e "${YELLOW}GitHub Repository: $GITHUB_ORG/$GITHUB_REPO${NC}"
echo -e "${YELLOW}App Registration Name: $APP_NAME${NC}"

if [[ "$WHATIF" == true ]]; then
    echo -e "${MAGENTA}Running in WhatIf mode - no changes will be made${NC}"
fi

# Step 1: Get Azure context
echo -e "\n${GREEN}1. Getting Azure context...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

CONTEXT=$(az account show 2>/dev/null) || {
    echo -e "${RED}Error: Not logged into Azure. Please run 'az login' first.${NC}"
    exit 1
}

SUBSCRIPTION_ID=$(echo $CONTEXT | jq -r '.id')
TENANT_ID=$(echo $CONTEXT | jq -r '.tenantId')
SUBSCRIPTION_NAME=$(echo $CONTEXT | jq -r '.name')

echo -e "   ${GRAY}Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)${NC}"
echo -e "   ${GRAY}Tenant: $TENANT_ID${NC}"

# Step 2: Create App Registration
echo -e "\n${GREEN}2. Creating App Registration...${NC}"
if [[ "$WHATIF" != true ]]; then
    APP_EXISTS=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
    if [[ -n "$APP_EXISTS" && "$APP_EXISTS" != "null" ]]; then
        echo -e "   ${YELLOW}App Registration '$APP_NAME' already exists${NC}"
        APP_ID="$APP_EXISTS"
    else
        az ad app create --display-name "$APP_NAME" > /dev/null
        APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
        echo -e "   ${GRAY}Created App Registration: $APP_ID${NC}"
    fi
else
    echo -e "   ${MAGENTA}[WhatIf] Would create App Registration '$APP_NAME'${NC}"
    APP_ID="00000000-0000-0000-0000-000000000000"
fi

# Step 3: Create Service Principal
echo -e "\n${GREEN}3. Creating Service Principal...${NC}"
if [[ "$WHATIF" != true ]]; then
    if az ad sp show --id "$APP_ID" &>/dev/null; then
        echo -e "   ${YELLOW}Service Principal already exists${NC}"
    else
        az ad sp create --id "$APP_ID" > /dev/null
        echo -e "   ${GRAY}Created Service Principal${NC}"
    fi
else
    echo -e "   ${MAGENTA}[WhatIf] Would create Service Principal for $APP_ID${NC}"
fi

# Step 4: Assign permissions
echo -e "\n${GREEN}4. Assigning Azure permissions...${NC}"
ROLES=("Contributor" "User Access Administrator")
for ROLE in "${ROLES[@]}"; do
    if [[ "$WHATIF" != true ]]; then
        EXISTING=$(az role assignment list --assignee "$APP_ID" --role "$ROLE" --scope "/subscriptions/$SUBSCRIPTION_ID" --query "length(@)")
        if [[ "$EXISTING" == "0" ]]; then
            az role assignment create --assignee "$APP_ID" --role "$ROLE" --scope "/subscriptions/$SUBSCRIPTION_ID" > /dev/null
            echo -e "   ${GRAY}Assigned '$ROLE' role${NC}"
        else
            echo -e "   ${YELLOW}'$ROLE' role already assigned${NC}"
        fi
    else
        echo -e "   ${MAGENTA}[WhatIf] Would assign '$ROLE' role to subscription scope${NC}"
    fi
done

# Step 5: Create federated credentials
echo -e "\n${GREEN}5. Creating federated identity credentials...${NC}"
BRANCHES=("main" "staging" "dev")
for BRANCH in "${BRANCHES[@]}"; do
    CREDENTIAL_NAME="podcast-hosting-$BRANCH"
    SUBJECT="repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/$BRANCH"
    
    if [[ "$WHATIF" != true ]]; then
        EXISTING=$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$CREDENTIAL_NAME'] | length(@)")
        if [[ "$EXISTING" != "0" ]]; then
            echo -e "   ${YELLOW}Federated credential '$CREDENTIAL_NAME' already exists${NC}"
        else
            CREDENTIAL_JSON=$(cat <<EOF
{
    "name": "$CREDENTIAL_NAME",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "$SUBJECT",
    "description": "GitHub Actions OIDC for $BRANCH branch",
    "audiences": ["api://AzureADTokenExchange"]
}
EOF
)
            az ad app federated-credential create --id "$APP_ID" --parameters "$CREDENTIAL_JSON" > /dev/null
            echo -e "   ${GRAY}Created federated credential for '$BRANCH' branch${NC}"
        fi
    else
        echo -e "   ${MAGENTA}[WhatIf] Would create federated credential for '$BRANCH' branch${NC}"
        echo -e "     ${GRAY}Subject: $SUBJECT${NC}"
    fi
done

# Step 6: Create PR credential (optional)
echo -e "\n${GREEN}6. Creating pull request federated credential...${NC}"
PR_CREDENTIAL_NAME="podcast-hosting-pr"
PR_SUBJECT="repo:$GITHUB_ORG/$GITHUB_REPO:pull_request"

if [[ "$WHATIF" != true ]]; then
    EXISTING=$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$PR_CREDENTIAL_NAME'] | length(@)")
    if [[ "$EXISTING" != "0" ]]; then
        echo -e "   ${YELLOW}Federated credential '$PR_CREDENTIAL_NAME' already exists${NC}"
    else
        PR_CREDENTIAL_JSON=$(cat <<EOF
{
    "name": "$PR_CREDENTIAL_NAME",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "$PR_SUBJECT",
    "description": "GitHub Actions OIDC for pull requests",
    "audiences": ["api://AzureADTokenExchange"]
}
EOF
)
        az ad app federated-credential create --id "$APP_ID" --parameters "$PR_CREDENTIAL_JSON" > /dev/null
        echo -e "   ${GRAY}Created federated credential for pull requests${NC}"
    fi
else
    echo -e "   ${MAGENTA}[WhatIf] Would create federated credential for pull requests${NC}"
    echo -e "     ${GRAY}Subject: $PR_SUBJECT${NC}"
fi

# Step 7: Display results
echo -e "\n${CYAN}=== Setup Complete ===${NC}"
echo -e "\n${YELLOW}Add these secrets to your GitHub repository:${NC}"
echo -e "${GREEN}AZURE_CLIENT_ID${NC} = $APP_ID"
echo -e "${GREEN}AZURE_TENANT_ID${NC} = $TENANT_ID"
echo -e "${GREEN}AZURE_SUBSCRIPTION_ID${NC} = $SUBSCRIPTION_ID"

echo -e "\n${YELLOW}GitHub Repository Settings:${NC}"
echo -e "${BLUE}Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "${GRAY}1. Add the above secrets to your GitHub repository${NC}"
echo -e "${GRAY}2. Create GitHub environments: dev, staging, prod${NC}"
echo -e "${GRAY}3. Test the deployment workflow${NC}"
echo -e "${GRAY}4. Remove any old AZURE_CREDENTIALS secret${NC}"

if [[ "$WHATIF" == true ]]; then
    echo -e "\n${MAGENTA}Run without --whatif to make actual changes${NC}"
fi

echo -e "\n${CYAN}For detailed setup instructions, see: AZURE_OIDC_SETUP_GUIDE.md${NC}"