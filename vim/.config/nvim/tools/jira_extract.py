#!/usr/bin/env python3
"""Extract basic information (title, description, ...) from a Jira issue.

Requires environment variables:
    JIRA_URL        Base URL of the Jira instance, e.g. https://yourcompany.atlassian.net
    JIRA_API_TOKEN  API token (or PAT) used as a Bearer token for authentication

Usage:
    python jira_extract.py ISSUE-123
"""

import json
import os
import sys
import urllib.error
import urllib.request


def fetch_issue(issue_key: str) -> dict:
    base_url = os.environ.get("JIRA_URL")
    api_token = os.environ.get("JIRA_API_TOKEN")

    if not base_url:
        raise SystemExit("Error: JIRA_URL environment variable is not set")
    if not api_token:
        raise SystemExit("Error: JIRA_API_TOKEN environment variable is not set")

    url = f"{base_url.rstrip('/')}/rest/api/2/issue/{issue_key}"
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {api_token}",
            "Accept": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(request) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raise SystemExit(
            f"Error: Jira API request failed ({e.code}): {e.read().decode('utf-8', 'ignore')}"
        )
    except urllib.error.URLError as e:
        raise SystemExit(f"Error: could not reach Jira at {url}: {e.reason}")


def extract_info(issue: dict) -> dict:
    fields = issue.get("fields", {})
    return {
        "key": issue.get("key"),
        "title": fields.get("summary"),
        "description": fields.get("description"),
        "status": (fields.get("status") or {}).get("name"),
        "assignee": (fields.get("assignee") or {}).get("displayName"),
        "reporter": (fields.get("reporter") or {}).get("displayName"),
        "created": fields.get("created"),
        "updated": fields.get("updated"),
    }


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(f"Usage: {sys.argv[0]} ISSUE-KEY")

    issue_key = sys.argv[1]
    issue = fetch_issue(issue_key)
    info = extract_info(issue)
    print(json.dumps(info, indent=2))


if __name__ == "__main__":
    main()
