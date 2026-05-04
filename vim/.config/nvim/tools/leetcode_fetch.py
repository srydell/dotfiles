"""Fetch LeetCode examples as C++-ready JSON for Neovim templates.

The CLI accepts a numeric LeetCode frontend ID, resolves it to a slug, caches
the raw GraphQL response, and prints a compact payload that is easy for a
snippet/template engine to expand into a local C++ solution file.

Cache files:
- ~/.cache/leetcode/id_to_slug.json
- ~/.cache/leetcode/problems/<slug>.json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from html import unescape
from html.parser import HTMLParser
from urllib import error, request


GRAPHQL_URL = "https://leetcode.com/graphql/"
CACHE_DIR = Path.home() / ".cache" / "leetcode"
ID_TO_SLUG_PATH = CACHE_DIR / "id_to_slug.json"
PROBLEMS_DIR = CACHE_DIR / "problems"

ID_TO_SLUG_QUERY = """
query problemsetQuestionList($limit: Int!, $filters: QuestionListFilterInput) {
  problemsetQuestionList: questionList(
    categorySlug: ""
    limit: $limit
    skip: 0
    filters: $filters
  ) {
    questions: data {
      questionFrontendId
      titleSlug
      title
    }
  }
}
"""

QUESTION_DATA_QUERY = """
query questionData($titleSlug: String!) {
  question(titleSlug: $titleSlug) {
    questionFrontendId
    title
    titleSlug
    difficulty
    content
    exampleTestcaseList
    sampleTestCase
    metaData
    codeSnippets {
      lang
      langSlug
      code
    }
  }
}
"""


def graphql_request(query, variables):
    """Send a GraphQL request and return the decoded response payload."""
    payload = json.dumps({"query": query, "variables": variables}).encode("utf-8")
    req = request.Request(
        GRAPHQL_URL,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "Referer": "https://leetcode.com",
            "User-Agent": "python-urllib/leetcode-fetch",
        },
        method="POST",
    )
    try:
        with request.urlopen(req) as response:
            body = response.read().decode("utf-8")
    except error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            raise RuntimeError(f"Network failure: HTTP {exc.code}: {body.strip() or exc.reason}") from exc
        _raise_for_graphql_errors(data)
        raise RuntimeError(f"Network failure: HTTP {exc.code}: {exc.reason}") from exc
    except error.URLError as exc:
        raise RuntimeError(f"Network failure: {exc}") from exc

    try:
        data = json.loads(body)
    except json.JSONDecodeError as exc:
        raise RuntimeError("Invalid JSON response from LeetCode") from exc

    _raise_for_graphql_errors(data)
    return data


def _raise_for_graphql_errors(data):
    errors = data.get("errors")
    if errors:
        message = "; ".join(item.get("message", "Unknown GraphQL error") for item in errors)
        raise RuntimeError(f"GraphQL error: {message}")


def fetch_id_to_slug_mapping():
    """Fetch and cache the frontend ID to title slug mapping."""
    data = graphql_request(ID_TO_SLUG_QUERY, {"limit": 5000, "filters": {}})
    questions = data["data"]["problemsetQuestionList"]["questions"]
    mapping = {
        str(question["questionFrontendId"]): question["titleSlug"]
        for question in questions
        if question.get("questionFrontendId") and question.get("titleSlug")
    }

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    ID_TO_SLUG_PATH.write_text(json.dumps(mapping, indent=2, sort_keys=True), encoding="utf-8")
    return mapping


def _search_slug_by_id(qid):
    data = graphql_request(
        ID_TO_SLUG_QUERY,
        {"limit": 50, "filters": {"searchKeywords": str(qid)}},
    )
    questions = data["data"]["problemsetQuestionList"]["questions"]
    for question in questions:
        if str(question.get("questionFrontendId")) == str(qid):
            return question.get("titleSlug")
    return None


def resolve_slug_from_id(qid, refresh=False):
    """Resolve a numeric frontend ID to a title slug."""
    qid = str(qid)
    if refresh or not ID_TO_SLUG_PATH.exists():
        mapping = fetch_id_to_slug_mapping()
    else:
        mapping = json.loads(ID_TO_SLUG_PATH.read_text(encoding="utf-8"))

    slug = mapping.get(qid)
    if slug:
        return slug

    slug = _search_slug_by_id(qid)
    if slug:
        mapping[qid] = slug
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        ID_TO_SLUG_PATH.write_text(json.dumps(mapping, indent=2, sort_keys=True), encoding="utf-8")
        return slug

    raise ValueError(f"Unknown LeetCode problem ID: {qid}")


def fetch_problem(slug):
    """Fetch raw problem data for a slug."""
    data = graphql_request(QUESTION_DATA_QUERY, {"titleSlug": slug})
    problem = data["data"]["question"]
    if problem is None:
        raise RuntimeError(f"Problem not found for slug: {slug}")
    return problem


def load_or_fetch_problem(slug, force=False):
    """Load a cached problem or fetch and cache it."""
    cache_path = PROBLEMS_DIR / f"{slug}.json"
    if cache_path.exists() and not force:
        problem = json.loads(cache_path.read_text(encoding="utf-8"))
        if _is_problem_cache_complete(problem):
            return problem

    problem = fetch_problem(slug)
    PROBLEMS_DIR.mkdir(parents=True, exist_ok=True)
    cache_path.write_text(json.dumps(problem, indent=2, sort_keys=True), encoding="utf-8")
    return problem


def _is_problem_cache_complete(problem):
    return "content" in problem


def normalize_problem(problem):
    """Convert LeetCode's raw GraphQL shape into a stable local shape.

    This keeps useful raw-ish fields such as metadata and the C++ starter code.
    The CLI does not print this directly; template_problem() trims it down to
    the smaller payload intended for snippet expansion.
    """
    metadata = {}
    if problem.get("metaData"):
        metadata = json.loads(problem["metaData"])

    cpp = None
    for snippet in problem.get("codeSnippets") or []:
        if snippet.get("langSlug") == "cpp":
            cpp = snippet.get("code")
            break

    param_names = [param.get("name") for param in metadata.get("params", []) if param.get("name")]

    examples = _extract_examples_from_content(problem.get("content"))
    if not examples:
        examples = [
            {"input": _format_testcase(example, param_names), "output": None, "explanation": None}
            for example in (problem.get("exampleTestcaseList") or [])
        ]

    return {
        "id": str(problem.get("questionFrontendId", "")),
        "title": problem.get("title"),
        "slug": problem.get("titleSlug"),
        "difficulty": problem.get("difficulty"),
        "description": _extract_description_from_content(problem.get("content")),
        "examples": examples,
        "sample": _format_testcase(problem.get("sampleTestCase"), param_names),
        "metadata": metadata,
        "cpp": cpp,
    }


def template_problem(normalized):
    """Return only the fields a C++ template needs."""
    params = normalized.get("metadata", {}).get("params", [])
    return_type = (normalized.get("metadata", {}).get("return") or {}).get("type")
    return {
        "id": normalized.get("id"),
        "title": normalized.get("title"),
        "slug": normalized.get("slug"),
        "difficulty": normalized.get("difficulty"),
        "description": normalized.get("description"),
        "signature": _build_cpp_signature(normalized.get("metadata", {})),
        "examples": [_enrich_example(example, params, return_type) for example in normalized.get("examples", [])],
    }


def _build_cpp_signature(metadata):
    """Build the Solution method signature using C++ type names."""
    params = metadata.get("params", [])
    return_type = (metadata.get("return") or {}).get("type")
    return {
        "name": metadata.get("name"),
        "return_type": _leetcode_type_to_cpp(return_type),
        "params": [
            {
                "name": param.get("name"),
                "type": _leetcode_type_to_cpp(param.get("type")),
            }
            for param in params
            if param.get("name")
        ],
    }


def _enrich_example(example, params, return_type):
    """Convert one example input into C++ argument declarations."""
    return {
        "arguments": _enrich_testcase(example.get("input"), params)["arguments"],
        "expected": _cpp_value(example.get("output"), return_type),
        "explanation": example.get("explanation"),
    }


def _enrich_testcase(testcase, params):
    """Parse one testcase and attach C++ values for each argument."""
    assignments = _parse_assignments(testcase, params)
    arguments = []
    declarations = []
    call_args = []

    for assignment in assignments:
        cxx_type = _leetcode_type_to_cpp(assignment["type"])
        cxx_value = _cpp_value(assignment["value"], assignment["type"])
        declaration = f"{cxx_type} {assignment['name']} = {cxx_value};"
        arguments.append(
            {
                "name": assignment["name"],
                "type": cxx_type,
                "value": cxx_value,
                "declaration": declaration,
            }
        )
        declarations.append(declaration)
        call_args.append(assignment["name"])

    return {
        "input": testcase,
        "arguments": arguments,
        "declarations": declarations,
        "call_args": call_args,
    }


def _parse_assignments(testcase, params):
    """Return name/type/value triples from LeetCode example input text.

    LeetCode may provide examples as "nums = [1,2], target = 3" from the
    problem HTML, or as newline-separated values from exampleTestcaseList.
    """
    if testcase is None:
        return []

    text = str(testcase).strip()
    if not text:
        return []

    param_by_name = {param.get("name"): param for param in params}
    chunks = _split_top_level_commas(text)
    assignments = []
    for chunk in chunks:
        if "=" not in chunk:
            continue
        name, value = chunk.split("=", 1)
        name = name.strip()
        if name not in param_by_name:
            continue
        assignments.append(
            {
                "name": name,
                "type": param_by_name[name].get("type"),
                "value": value.strip(),
            }
        )

    if assignments:
        return assignments

    values = text.splitlines()
    if len(values) == len(params):
        return [
            {
                "name": param.get("name"),
                "type": param.get("type"),
                "value": value.strip(),
            }
            for param, value in zip(params, values)
            if param.get("name")
        ]

    if len(params) == 1 and params[0].get("name"):
        return [
            {
                "name": params[0].get("name"),
                "type": params[0].get("type"),
                "value": text,
            }
        ]

    return []


def _split_top_level_commas(text):
    """Split comma-separated assignments without splitting inside arrays."""
    chunks = []
    start = 0
    depth = 0
    quote = None
    escape = False

    for index, char in enumerate(text):
        if quote:
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == quote:
                quote = None
            continue

        if char in {"'", '"'}:
            quote = char
        elif char in "[({":
            depth += 1
        elif char in "])}":
            depth = max(0, depth - 1)
        elif char == "," and depth == 0:
            chunks.append(text[start:index].strip())
            start = index + 1

    chunks.append(text[start:].strip())
    return [chunk for chunk in chunks if chunk]


def _leetcode_type_to_cpp(le_type):
    """Translate LeetCode metadata types into C++ types used by templates."""
    if not le_type:
        return "auto"

    le_type = le_type.strip()
    scalar_types = {
        "boolean": "bool",
        "character": "char",
        "integer": "int",
        "long": "long long",
        "double": "double",
        "string": "string",
        "void": "void",
        "ListNode": "ListNode*",
        "TreeNode": "TreeNode*",
        "Node": "Node*",
    }
    if le_type in scalar_types:
        return scalar_types[le_type]
    if le_type.startswith("list<") and le_type.endswith(">"):
        return f"vector<{_leetcode_type_to_cpp(le_type[5:-1])}>"
    if le_type.endswith("[]"):
        return f"vector<{_leetcode_type_to_cpp(le_type[:-2])}>"
    return le_type


def _cpp_value(value, le_type):
    """Format a LeetCode example value as a C++ expression."""
    if value is None:
        return "nullptr" if le_type in {"ListNode", "TreeNode", "Node"} else "{}"

    text = str(value).strip()
    if le_type == "TreeNode":
        return f"create({_cpp_vector_initializer(text, 'optional<int>')})"
    if le_type == "ListNode":
        return f"create({_cpp_vector_initializer(text, 'int')})"
    if le_type and _is_sequence_type(le_type):
        return _cpp_array_value(text, le_type)
    if le_type == "string":
        return _cpp_string(text)
    if le_type == "character":
        return _cpp_char(text)
    if le_type == "boolean":
        return text.lower()
    if text == "null":
        return "nullptr"
    if text.startswith("[") and text.endswith("]"):
        return _cpp_array_value(text, "integer[]")
    if text.startswith('"') and text.endswith('"'):
        return _cpp_string(text)
    return text


def _cpp_array_value(text, le_type):
    """Format a LeetCode sequence value as a C++ vector expression."""
    values = _parse_json_like(text)
    cpp_type = _leetcode_type_to_cpp(le_type)
    if values is None:
        return f"{cpp_type}{{{text}}}"
    return f"{cpp_type}{_cpp_braced_list(values, _sequence_item_type(le_type))}"


def _cpp_vector_initializer(text, cpp_type):
    values = _parse_json_like(text)
    if values is None:
        return f"vector<{cpp_type}>{{{text}}}"
    return f"vector<{cpp_type}>{_cpp_braced_list(values, cpp_type)}"


def _is_sequence_type(le_type):
    return le_type.endswith("[]") or (le_type.startswith("list<") and le_type.endswith(">"))


def _sequence_item_type(le_type):
    if le_type.endswith("[]"):
        return le_type[:-2]
    return le_type[5:-1]


def _cpp_braced_list(value, item_type):
    """Recursively format parsed JSON values as C++ initializer braces."""
    if isinstance(value, list):
        inner_type = _sequence_item_type(item_type) if isinstance(item_type, str) and _is_sequence_type(item_type) else item_type
        return "{" + ", ".join(_cpp_braced_list(item, inner_type) for item in value) + "}"
    if value is None:
        return "nullopt" if item_type == "optional<int>" else "nullptr"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        if item_type == "character":
            return _cpp_char(value)
        return _cpp_string(value)
    return str(value)


def _parse_json_like(text):
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return None


def _cpp_string(text):
    if text.startswith('"') and text.endswith('"'):
        return text
    return json.dumps(text)


def _cpp_char(text):
    if text.startswith("'") and text.endswith("'"):
        return text
    if text.startswith('"') and text.endswith('"'):
        text = json.loads(text)
    return "'" + text.replace("\\", "\\\\").replace("'", "\\'") + "'"


def _format_testcase(testcase, param_names):
    if testcase is None:
        return None

    text = str(testcase).strip()
    if not text:
        return text

    values = text.splitlines()
    if len(values) > 1 and len(values) == len(param_names):
        return ", ".join(f"{name} = {value}" for name, value in zip(param_names, values))

    return text


class _HTMLToTextParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_starttag(self, tag, attrs):
        if tag in {"p", "div", "section", "article", "br", "li", "ul", "ol", "pre"}:
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in {"p", "div", "section", "article", "li", "ul", "ol", "pre"}:
            self.parts.append("\n")

    def handle_data(self, data):
        self.parts.append(data)

    def get_text(self):
        return unescape("".join(self.parts))


def _extract_examples_from_content(content):
    if not content:
        return []

    parser = _HTMLToTextParser()
    parser.feed(content)
    text = parser.get_text()
    matches = re.findall(
        r"Example\s*\d*:\s*Input:\s*(.*?)\s*Output:\s*(.*?)(?=\s*Example\s*\d*:|\s*Constraints:|\s*Follow-up:|\Z)",
        text,
        flags=re.DOTALL,
    )

    examples = []
    for raw_input, raw_output in matches:
        example_input = _collapse_whitespace(raw_input)
        example_output, explanation = _split_output_and_explanation(raw_output)
        if example_input or example_output:
            examples.append(
                {
                    "input": example_input or None,
                    "output": example_output or None,
                    "explanation": explanation or None,
                }
            )
    return examples


def _extract_description_from_content(content):
    if not content:
        return None

    parser = _HTMLToTextParser()
    parser.feed(content)
    text = parser.get_text()
    description = re.split(
        r"\s*(?:Example\s*\d*:|Constraints:|Follow-up:)\s*",
        text,
        maxsplit=1,
        flags=re.DOTALL,
    )[0]
    description = _collapse_whitespace(description)
    return description or None


def _collapse_whitespace(text):
    return re.sub(r"\s+", " ", text).strip()


def _split_output_and_explanation(text):
    collapsed = _collapse_whitespace(text)
    if not collapsed:
        return None, None

    parts = re.split(r"\bExplanation:\s*", collapsed, maxsplit=1)
    if len(parts) == 2:
        return parts[0].strip() or None, parts[1].strip() or None
    return collapsed, None


def main():
    parser = argparse.ArgumentParser(description="Fetch LeetCode problems by numeric ID.")
    parser.add_argument("qid", help="Numeric LeetCode problem ID")
    parser.add_argument("--force", action="store_true", help="Refetch problem even if cached")
    parser.add_argument(
        "--refresh-ids",
        action="store_true",
        help="Refetch the ID to slug mapping before resolving",
    )
    args = parser.parse_args()

    if not str(args.qid).isdigit():
        print(f"Expected a numeric LeetCode problem ID, got: {args.qid}", file=sys.stderr)
        return 1

    try:
        slug = resolve_slug_from_id(args.qid, refresh=args.refresh_ids)
        problem = load_or_fetch_problem(slug, force=args.force)
        normalized = normalize_problem(problem)
        template = template_problem(normalized)
    except (ValueError, RuntimeError, json.JSONDecodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 1

    json.dump(template, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
