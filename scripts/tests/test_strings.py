"""Catalog failures that must stop CI before malformed translations reach printf."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("rightkit_strings", Path(__file__).parents[1] / "strings.py")
strings = importlib.util.module_from_spec(spec)
spec.loader.exec_module(strings)


class CatalogValidationTests(unittest.TestCase):
    def test_positional_reordering_keeps_argument_types(self):
        self.assertEqual(strings.placeholders("%@ %d"), strings.placeholders("%2$d %1$@"))
        self.assertNotEqual(strings.placeholders("%@ %d"), strings.placeholders("%2$@ %1$d"))
        self.assertNotEqual(strings.placeholders("%@ %@"), strings.placeholders("%1$@ %1$@"))

    def test_missing_or_changed_argument_is_rejected(self):
        self.assertNotEqual(strings.placeholders("%@ %d"), strings.placeholders("%@"))
        self.assertNotEqual(strings.placeholders("%d"), strings.placeholders("%@"))
        self.assertEqual(strings.placeholders("100%% %@"), strings.placeholders("%@ 100%%"))

    def test_shortcut_application_token_is_required(self):
        self.assertNotEqual(strings.placeholders("用 ${applicationName} 拷贝路径"), strings.placeholders("パスをコピー"))

    def test_catalog_requires_all_languages_and_translated_state(self):
        catalog = {"sourceLanguage": "zh-Hans", "strings": {"取消": {"localizations": {
            lang: {"stringUnit": {"state": "translated", "value": "取消"}}
            for lang in strings.SUPPORTED}}}}
        self.assertEqual(strings.validate_catalog(catalog, "fixture"), [])
        catalog["strings"]["取消"]["localizations"]["ja"]["stringUnit"]["state"] = "needs_review"
        self.assertEqual(len(strings.validate_catalog(catalog, "fixture")), 1)
        del catalog["strings"]["取消"]["localizations"]["ko"]
        self.assertEqual(len(strings.validate_catalog(catalog, "fixture")), 2)
