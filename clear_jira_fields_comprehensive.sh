#!/bin/bash

# Comprehensive script to clear all fields in a Jira task
# Usage: ./clear_jira_fields_comprehensive.sh <ISSUE_KEY>
# Example: ./clear_jira_fields_comprehensive.sh PROJ-123

set -e

# Check if jira-cli is installed
if ! command -v jira &> /dev/null; then
    echo "Error: jira-cli is not installed."
    echo "Install it using: brew install go-jira"
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

# Get current issue details
echo "Fetching current issue details..."
jira view "$ISSUE_KEY" --template=json > /tmp/jira_issue.json

# Extract custom field IDs from the issue
echo "Identifying custom fields..."
CUSTOM_FIELDS=$(jq -r '.fields | to_entries[] | select(.key | startswith("customfield_")) | .key' /tmp/jira_issue.json 2>/dev/null || echo "")

# Build the clear payload
CLEAR_PAYLOAD='{"fields":{'

# Clear standard fields
CLEAR_PAYLOAD+='"summary":"",'
CLEAR_PAYLOAD+='"description":"",'
CLEAR_PAYLOAD+='"assignee":null,'
CLEAR_PAYLOAD+='"reporter":null,'
CLEAR_PAYLOAD+='"priority":null,'
CLEAR_PAYLOAD+='"labels":[],'
CLEAR_PAYLOAD+='"components":[],'
CLEAR_PAYLOAD+='"fixVersions":[],'
CLEAR_PAYLOAD+='"versions":[],'
CLEAR_PAYLOAD+='"environment":"",'
CLEAR_PAYLOAD+='"duedate":null,'
CLEAR_PAYLOAD+='"timeestimate":null,'
CLEAR_PAYLOAD+='"timeoriginalestimate":null'

# Add custom fields if any exist
if [ ! -z "$CUSTOM_FIELDS" ]; then
    echo "Found custom fields: $CUSTOM_FIELDS"
    for field in $CUSTOM_FIELDS; do
        CLEAR_PAYLOAD+=",\"$field\":null"
    done
fi

CLEAR_PAYLOAD+='}}'

echo "Attempting to clear all fields..."
echo "$CLEAR_PAYLOAD" | jira edit "$ISSUE_KEY" --input -

echo "Fields cleared successfully!"
echo "Note: Some system fields (like issue type, project, status) cannot be cleared."

# Clean up
rm -f /tmp/jira_issue.json 