"""Repeatable locale and rendered-page checks; never writes website/dist.

Run: python3 -m unittest discover -s website/tests -p 'test_*.py' -v
"""
import contextlib
import importlib.util
import io
import json
from html.parser import HTMLParser
from pathlib import Path
import re
import tempfile
import unittest
from urllib.parse import urljoin, urlsplit

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {'zh': ('zh-Hans', '/', 'zh_CN'), 'en': ('en', '/en/', 'en_US'),
            'ja': ('ja', '/ja/', 'ja_JP'), 'ko': ('ko', '/ko/', 'ko_KR')}
# These values drive routing, asset lookup or demo command applicability, not prose.
TECHNICAL = {'id', 'key', 'icon', 'art', 'tint', 'href', 'x', 'y', 'src', 'num',
             'ext', 'kind', 'role', 'for'}
PLACEHOLDERS = re.compile(r'\{\w+\}')


def leaves(value, path=()):
    if isinstance(value, dict):
        for key, item in value.items():
            yield from leaves(item, path + (key,))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            yield from leaves(item, path + (index,))
    else:
        yield path, value


class Page(HTMLParser):
    def __init__(self, source):
        super().__init__()
        self.tags = []
        self.scripts = {}
        self.script_id = None
        self.visible = []
        self.feed(source)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.tags.append((tag, attrs))
        if tag == 'script':
            self.script_id = attrs.get('id', '')

    def handle_endtag(self, tag):
        if tag == 'script':
            self.script_id = None

    def handle_data(self, data):
        if self.script_id is not None:
            self.scripts[self.script_id] = self.scripts.get(self.script_id, '') + data
        else:
            self.visible.append(data)


class LocaleContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.content = json.loads((ROOT / 'content.json').read_text())

    def test_all_four_locales_have_correct_metadata(self):
        self.assertEqual(set(self.content), set(EXPECTED))
        for key, (lang, path, og) in EXPECTED.items():
            with self.subTest(locale=key):
                strings = self.content[key]
                self.assertEqual((strings['lang'], strings['path'], strings['ogLocale']), (lang, path, og))
                self.assertEqual(strings['privacy']['home'], path.lstrip('/'))

    def test_translation_shape_and_placeholder_contract(self):
        def compare(source, target, path):
            if path.endswith('.sections.settings.preview'):
                self.assertIsInstance(target, dict)
                return
            self.assertIs(type(target), type(source), path)
            if isinstance(source, dict):
                self.assertEqual(source.keys(), target.keys(), path)
                for key in source:
                    compare(source[key], target[key], path + '.' + key)
            elif isinstance(source, list):
                self.assertEqual(len(source), len(target), path)
                for index, (a, b) in enumerate(zip(source, target)):
                    compare(a, b, f'{path}.{index}')
            elif isinstance(source, str):
                self.assertEqual(sorted(PLACEHOLDERS.findall(source)), sorted(PLACEHOLDERS.findall(target)), path)
            else:
                self.assertEqual(source, target, path)
        for locale, target in self.content.items():
            with self.subTest(locale=locale):
                compare(self.content['en'], target, locale)

    def test_technical_fields_remain_identical(self):
        original = dict(leaves(self.content['en']))
        for locale, target in self.content.items():
            for path, value in leaves(target):
                if path[:3] == ('sections', 'settings', 'preview'):
                    continue
                # Locale-level paths and privacy.home intentionally differ.
                immutable = any(part in TECHNICAL for part in path)
                immutable |= path[:3] == ('sections', 'new', 'types')
                immutable |= path in {('demo', 'home'), ('demo', 'folder')}
                immutable |= len(path) > 2 and path[:2] == ('demo', 'places') and path[-1] == 'path'
                if immutable:
                    with self.subTest(locale=locale, field=path):
                        self.assertEqual(value, original[path])

    def test_optional_settings_preview_is_locale_specific(self):
        for key, strings in self.content.items():
            with self.subTest(locale=key):
                preview = strings['sections']['settings']['preview']
                if key in ('zh', 'en'):
                    self.assertEqual(preview, {})
                else:
                    self.assertEqual(set(preview), {'src', 'alt', 'caption'})
                    self.assertTrue(all(isinstance(value, str) and value.strip() for value in preview.values()))
                    self.assertNotEqual(preview['src'], self.content['ja' if key == 'ko' else 'ko']['sections']['settings']['preview']['src'])

    def test_copy_has_no_em_dash_or_unresolved_template_syntax(self):
        for locale, target in self.content.items():
            for path, value in leaves(target):
                if isinstance(value, str):
                    with self.subTest(locale=locale, field=path):
                        self.assertNotIn('\u2014', value)
                        self.assertNotIn('{{', value)
                        self.assertNotIn('{%', value)


class RenderedPages(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('rightkit_website_build', ROOT / 'build.py')
        cls.build = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.build)
        cls.content = json.loads((ROOT / 'content.json').read_text())
        cls.site = json.loads((ROOT / 'site.json').read_text())
        # build.main prints paths relative to ROOT; keep the temporary tree there.
        cls.temporary = tempfile.TemporaryDirectory(prefix='.test-i18n-', dir=ROOT)
        cls.dist = Path(cls.temporary.name) / 'dist'
        cls.build.DIST = cls.dist
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                cls.build.main()
        except BaseException:
            cls.temporary.cleanup()
            raise
        cls.pages = {}
        for theme in ('', 'ak/'):
            for key, (_, locale_path, _) in EXPECTED.items():
                for sub in ('', 'privacy/'):
                    path = '/' + theme + locale_path.lstrip('/') + sub
                    source = (cls.dist / path.lstrip('/') / 'index.html').read_text()
                    cls.pages[(theme, key, sub)] = (path, source, Page(source))

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def test_canonical_and_reciprocal_hreflang(self):
        for (theme, key, sub), (path, source, page) in self.pages.items():
            with self.subTest(theme=theme, locale=key, privacy=bool(sub)):
                html_attrs = next(a for tag, a in page.tags if tag == 'html')
                self.assertEqual(html_attrs['lang'], EXPECTED[key][0])
                canonical = [a['href'] for tag, a in page.tags if tag == 'link' and a.get('rel') == 'canonical']
                self.assertEqual(canonical, [self.site['url'] + EXPECTED[key][1] + sub])
                alternates = {a['hreflang']: a['href'] for tag, a in page.tags if tag == 'link' and a.get('rel') == 'alternate'}
                expected = {lang: self.site['url'] + locale_path + sub
                            for lang, locale_path, _ in EXPECTED.values()}
                expected['x-default'] = self.site['url'] + '/' + sub
                self.assertEqual(alternates, expected)
                # Every alternate's generated page links back to this exact URL.
                for other in EXPECTED:
                    reciprocal = self.pages[(theme, other, sub)][2]
                    self.assertTrue(any(tag == 'link' and a.get('hreflang') == EXPECTED[key][0]
                                        and a.get('href') == canonical[0] for tag, a in reciprocal.tags))

    def test_language_navigation_keeps_theme_and_page_kind(self):
        for (theme, key, sub), (path, source, page) in self.pages.items():
            with self.subTest(theme=theme, locale=key, privacy=bool(sub)):
                links = [a for tag, a in page.tags if tag == 'a' and 'data-language' in a]
                self.assertEqual(set(a['data-language'] for a in links), set(EXPECTED))
                config = json.loads(page.scripts['language-data'])
                self.assertEqual(config['current'], key)
                self.assertEqual(config['defaultEntry'], key == 'zh')
                self.assertEqual(set(a['key'] for a in config['languages']), set(EXPECTED))
                for link in links:
                    other = link['data-language']
                    expected_path = '/' + theme + EXPECTED[other][1].lstrip('/') + sub
                    destination = urlsplit(urljoin(self.site['url'] + path, link['href']))
                    self.assertEqual(destination.path, expected_path)
                    self.assertEqual(destination.query, 'lang=zh' if other == 'zh' else '')
                    self.assertEqual(link.get('aria-current'), 'page' if other == key else None)
                    self.assertEqual(link['lang'], EXPECTED[other][0])
                    self.assertEqual(link['hreflang'], EXPECTED[other][0])
                for tag, attrs in page.tags:
                    if tag != 'a':
                        continue
                    if 'brand' in attrs.get('class', '').split():
                        self.assertEqual(urlsplit(urljoin(self.site['url'] + path, attrs['href'])).path,
                                         '/' + theme + EXPECTED[key][1].lstrip('/'))
                    href = attrs.get('href', '')
                    if 'privacy/' in href and 'data-language' not in attrs:
                        self.assertEqual(urlsplit(urljoin(self.site['url'] + path, href)).path,
                                         '/' + theme + EXPECTED[key][1].lstrip('/') + 'privacy/')
                        self.assertEqual(urlsplit(href).query, 'lang=zh' if key == 'zh' else '')

    def test_assets_resolve_and_templates_are_fully_rendered(self):
        for (theme, key, sub), (path, source, page) in self.pages.items():
            with self.subTest(theme=theme, locale=key, privacy=bool(sub)):
                self.assertNotRegex(source, r'\{\{|\{%')
                visible = ''.join(page.visible)
                self.assertNotIn('\u2014', visible)
                self.assertNotRegex(visible, r'\{(?:version|year)\}')
                for tag, attrs in page.tags:
                    urls = []
                    for attr in ('src', 'data-src', 'poster'):
                        if attrs.get(attr):
                            urls.append(attrs[attr])
                    for attr in ('srcset', 'imagesrcset'):
                        urls += [part.strip().split()[0] for part in attrs.get(attr, '').split(',') if part.strip()]
                    if tag == 'link' and attrs.get('rel') not in ('canonical', 'alternate') and attrs.get('href'):
                        urls.append(attrs['href'])
                    for asset in urls:
                        resolved = urlsplit(urljoin('https://local.test' + path, asset))
                        if resolved.netloc == 'local.test':
                            self.assertTrue((self.dist / resolved.path.lstrip('/')).is_file(), (path, asset))


if __name__ == '__main__':
    unittest.main()
