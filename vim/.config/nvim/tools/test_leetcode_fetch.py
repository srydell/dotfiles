import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import leetcode_fetch


class LeetCodeFetchTests(unittest.TestCase):
    def test_resolve_slug_from_id_uses_cached_mapping(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            mapping_path = Path(tmpdir) / "id_to_slug.json"
            mapping_path.write_text(json.dumps({"345": "reverse-vowels-of-a-string"}), encoding="utf-8")

            with mock.patch.object(leetcode_fetch, "ID_TO_SLUG_PATH", mapping_path):
                slug = leetcode_fetch.resolve_slug_from_id("345")

            self.assertEqual(slug, "reverse-vowels-of-a-string")

    def test_resolve_slug_from_id_fetches_mapping_when_cache_missing(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            mapping_path = Path(tmpdir) / "id_to_slug.json"
            with mock.patch.object(leetcode_fetch, "ID_TO_SLUG_PATH", mapping_path):
                with mock.patch.object(
                    leetcode_fetch,
                    "fetch_id_to_slug_mapping",
                    return_value={"345": "reverse-vowels-of-a-string"},
                ) as fetch_mapping:
                    slug = leetcode_fetch.resolve_slug_from_id("345")

            self.assertEqual(slug, "reverse-vowels-of-a-string")
            fetch_mapping.assert_called_once_with()

    def test_load_or_fetch_problem_uses_cache_unless_force(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            problems_dir = Path(tmpdir)
            cache_path = problems_dir / "reverse-vowels-of-a-string.json"
            cache_path.write_text(json.dumps({"title": "cached", "content": ""}), encoding="utf-8")

            with mock.patch.object(leetcode_fetch, "PROBLEMS_DIR", problems_dir):
                with mock.patch.object(leetcode_fetch, "fetch_problem") as fetch_problem:
                    cached = leetcode_fetch.load_or_fetch_problem("reverse-vowels-of-a-string")

            self.assertEqual(cached["title"], "cached")
            fetch_problem.assert_not_called()

            with mock.patch.object(leetcode_fetch, "PROBLEMS_DIR", problems_dir):
                with mock.patch.object(
                    leetcode_fetch,
                    "fetch_problem",
                    return_value={"title": "fresh"},
                ) as fetch_problem:
                    fresh = leetcode_fetch.load_or_fetch_problem(
                        "reverse-vowels-of-a-string", force=True
                    )

            self.assertEqual(fresh["title"], "fresh")
            fetch_problem.assert_called_once_with("reverse-vowels-of-a-string")

    def test_load_or_fetch_problem_refetches_stale_cache(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            problems_dir = Path(tmpdir)
            cache_path = problems_dir / "integer-to-roman.json"
            cache_path.write_text(json.dumps({"title": "stale"}), encoding="utf-8")

            with mock.patch.object(leetcode_fetch, "PROBLEMS_DIR", problems_dir):
                with mock.patch.object(
                    leetcode_fetch,
                    "fetch_problem",
                    return_value={"title": "fresh", "content": "<p>Example</p>"},
                ) as fetch_problem:
                    problem = leetcode_fetch.load_or_fetch_problem("integer-to-roman")

            self.assertEqual(problem["title"], "fresh")
            fetch_problem.assert_called_once_with("integer-to-roman")

    def test_normalize_problem_extracts_cpp_snippet(self):
        problem = {
            "questionFrontendId": "345",
            "title": "Reverse Vowels of a String",
            "titleSlug": "reverse-vowels-of-a-string",
            "difficulty": "Easy",
            "content": "",
            "exampleTestcaseList": ["hello"],
            "sampleTestCase": "hello",
            "metaData": "{}",
            "codeSnippets": [
                {"langSlug": "python3", "code": "class Solution: pass"},
                {"langSlug": "cpp", "code": "class Solution {};"},
            ],
        }

        normalized = leetcode_fetch.normalize_problem(problem)

        self.assertEqual(normalized["cpp"], "class Solution {};")

    def test_normalize_problem_parses_metadata_json(self):
        problem = {
            "questionFrontendId": "345",
            "title": "Reverse Vowels of a String",
            "titleSlug": "reverse-vowels-of-a-string",
            "difficulty": "Easy",
            "content": "",
            "exampleTestcaseList": [],
            "sampleTestCase": "",
            "metaData": '{"name":"reverseVowels","params":[{"name":"s"}]}',
            "codeSnippets": [],
        }

        normalized = leetcode_fetch.normalize_problem(problem)

        self.assertEqual(normalized["metadata"]["name"], "reverseVowels")
        self.assertEqual(normalized["metadata"]["params"][0]["name"], "s")

    def test_normalize_problem_formats_multi_argument_testcases(self):
        problem = {
            "questionFrontendId": "223",
            "title": "Rectangle Area",
            "titleSlug": "rectangle-area",
            "difficulty": "Medium",
            "content": "",
            "exampleTestcaseList": ["-3\n0\n3\n4\n0\n-1\n9\n2"],
            "sampleTestCase": "-3\n0\n3\n4\n0\n-1\n9\n2",
            "metaData": json.dumps(
                {
                    "params": [
                        {"name": "ax1"},
                        {"name": "ay1"},
                        {"name": "ax2"},
                        {"name": "ay2"},
                        {"name": "bx1"},
                        {"name": "by1"},
                        {"name": "bx2"},
                        {"name": "by2"},
                    ]
                }
            ),
            "codeSnippets": [],
        }

        normalized = leetcode_fetch.normalize_problem(problem)

        expected = (
            "ax1 = -3, ay1 = 0, ax2 = 3, ay2 = 4, "
            "bx1 = 0, by1 = -1, bx2 = 9, by2 = 2"
        )
        self.assertEqual(
            normalized["examples"],
            [{"input": expected, "output": None, "explanation": None}],
        )
        self.assertEqual(normalized["sample"], expected)

    def test_normalize_problem_prefers_examples_from_content(self):
        problem = {
            "questionFrontendId": "223",
            "title": "Rectangle Area",
            "titleSlug": "rectangle-area",
            "difficulty": "Medium",
            "content": """
                <p><strong>Example 1:</strong></p>
                <p><strong>Input:</strong> ax1 = -3, ay1 = 0, ax2 = 3, ay2 = 4, bx1 = 0, by1 = -1, bx2 = 9, by2 = 2</p>
                <p><strong>Output:</strong> 45</p>
                <p><strong>Example 2:</strong></p>
                <p><strong>Input:</strong> ax1 = -2, ay1 = -2, ax2 = 2, ay2 = 2, bx1 = -2, by1 = -2, bx2 = 2, by2 = 2</p>
                <p><strong>Output:</strong> 16</p>
                <p><strong>Constraints:</strong></p>
            """,
            "exampleTestcaseList": ["-3\n0\n3\n4\n0\n-1\n9\n2"],
            "sampleTestCase": "-3\n0\n3\n4\n0\n-1\n9\n2",
            "metaData": '{"params":[]}',
            "codeSnippets": [],
        }

        normalized = leetcode_fetch.normalize_problem(problem)

        self.assertEqual(
            normalized["examples"],
            [
                {
                    "input": "ax1 = -3, ay1 = 0, ax2 = 3, ay2 = 4, bx1 = 0, by1 = -1, bx2 = 9, by2 = 2",
                    "output": "45",
                    "explanation": None,
                },
                {
                    "input": "ax1 = -2, ay1 = -2, ax2 = 2, ay2 = 2, bx1 = -2, by1 = -2, bx2 = 2, by2 = 2",
                    "output": "16",
                    "explanation": None,
                },
            ],
        )

    def test_normalize_problem_splits_example_explanation(self):
        problem = {
            "questionFrontendId": "121",
            "title": "Best Time to Buy and Sell Stock",
            "titleSlug": "best-time-to-buy-and-sell-stock",
            "difficulty": "Easy",
            "content": """
                <p><strong>Example 2:</strong></p>
                <p><strong>Input:</strong> prices = [7,6,4,3,1]</p>
                <p><strong>Output:</strong> 0</p>
                <p><strong>Explanation:</strong> There is no way to make a positive profit, so we never buy the stock to achieve the maximum profit of 0.</p>
                <p><strong>Constraints:</strong></p>
            """,
            "exampleTestcaseList": [],
            "sampleTestCase": "",
            "metaData": '{"params":[]}',
            "codeSnippets": [],
        }

        normalized = leetcode_fetch.normalize_problem(problem)

        self.assertEqual(
            normalized["examples"],
            [
                {
                    "input": "prices = [7,6,4,3,1]",
                    "output": "0",
                    "explanation": "There is no way to make a positive profit, so we never buy the stock to achieve the maximum profit of 0.",
                }
            ],
        )

    def test_unknown_id_raises_error(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            mapping_path = Path(tmpdir) / "id_to_slug.json"
            mapping_path.write_text(json.dumps({"1": "two-sum"}), encoding="utf-8")

            with mock.patch.object(leetcode_fetch, "ID_TO_SLUG_PATH", mapping_path):
                with mock.patch.object(leetcode_fetch, "_search_slug_by_id", return_value=None):
                    with self.assertRaisesRegex(ValueError, "Unknown LeetCode problem ID: 345"):
                        leetcode_fetch.resolve_slug_from_id("345")

    def test_resolve_slug_from_id_falls_back_to_search(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            cache_dir = Path(tmpdir)
            mapping_path = cache_dir / "id_to_slug.json"
            mapping_path.write_text(json.dumps({"1": "two-sum"}), encoding="utf-8")

            with mock.patch.object(leetcode_fetch, "CACHE_DIR", cache_dir):
                with mock.patch.object(leetcode_fetch, "ID_TO_SLUG_PATH", mapping_path):
                    with mock.patch.object(
                        leetcode_fetch,
                        "_search_slug_by_id",
                        return_value="rectangle-area",
                    ) as search_slug:
                        slug = leetcode_fetch.resolve_slug_from_id("223")

            self.assertEqual(slug, "rectangle-area")
            self.assertEqual(
                json.loads(mapping_path.read_text(encoding="utf-8"))["223"],
                "rectangle-area",
            )
            search_slug.assert_called_once_with("223")

    def test_graphql_error_handling(self):
        response_payload = json.dumps(
            {"errors": [{"message": "Something went wrong"}]}
        ).encode("utf-8")
        response = mock.MagicMock()
        response.read.return_value = response_payload
        response.__enter__.return_value = response
        response.__exit__.return_value = None

        with mock.patch("urllib.request.urlopen", return_value=response):
            with self.assertRaisesRegex(RuntimeError, "GraphQL error: Something went wrong"):
                leetcode_fetch.graphql_request("query {}", {})


if __name__ == "__main__":
    unittest.main()
