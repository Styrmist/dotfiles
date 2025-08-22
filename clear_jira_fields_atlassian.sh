#!/bin/bash

# Script to clear all fields in a Jira task using Atlassian CLI
# Usage: ./clear_jira_fields_atlassian.sh <ISSUE_KEY>
# Example: ./clear_jira_fields_atlassian.sh PROJ-123

set -e

# Check if atlassian CLI is installed
if ! command -v atl &> /dev/null; then
    echo "Error: Atlassian CLI is not installed."
    echo "Install it using: npm install -g @atlassian/cli"
    echo "Or download from: https://marketplace.atlassian.com/apps/1212213/atlassian-cli"
    exit 1
fi

# Check if issue key is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <ISSUE_KEY>"
    echo "Example: $0 PROJ-123"
    exit 1
fi

ISSUE_KEY="$1"

echo "Clearing all fields for issue: $ISSUE_KEY"

# Create a JSON payload to clear common fields
CLEAR_PAYLOAD=$(cat <<EOF
{
  "fields": {
    "summary": "",
    "description": "",
    "assignee": null,
    "reporter": null,
    "priority": null,
    "labels": [],
    "components": [],
    "fixVersions": [],
    "versions": [],
    "environment": "",
    "duedate": null,
    "timeestimate": null,
    "timeoriginalestimate": null
  }
}
EOF
)

echo "Attempting to clear fields using Atlassian CLI..."
echo "$CLEAR_PAYLOAD" | atl jira issue update "$ISSUE_KEY" --data -

echo "Fields cleared successfully!"
echo "Note: Some system fields cannot be cleared due to Jira restrictions." 