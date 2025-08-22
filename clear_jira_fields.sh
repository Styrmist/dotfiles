#!/bin/bash

# Script to clear all fields in a Jira task using jira-cli
# Usage: ./clear_jira_fields.sh <ISSUE_KEY>
# Example: ./clear_jira_fields.sh PROJ-123

set -e

# Check if jira-cli is installed
if ! command -v jira &> /dev/null; then
    echo "Error: jira-cli is not installed."
    echo "Install it using: brew install go-jira"
    echo "Or download from: https://github.com/go-jira/jira"
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

# Get current issue details to see what fields exist
echo "Fetching current issue details..."
jira view "$ISSUE_KEY" --template=json > /tmp/jira_issue.json

# Create a JSON payload to clear common fields
# Note: Some fields cannot be cleared due to Jira restrictions
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
    "timeoriginalestimate": null,
    "timetracking": {
      "originalEstimate": "",
      "remainingEstimate": ""
    }
  }
}
EOF
)

echo "Attempting to clear fields..."
echo "$CLEAR_PAYLOAD" | jira edit "$ISSUE_KEY" --input -

echo "Fields cleared successfully!"
echo "Note: Some system fields (like issue type, project, status) cannot be cleared."
echo "You may need to manually clear additional custom fields through the Jira web interface."

# Clean up
rm -f /tmp/jira_issue.json 