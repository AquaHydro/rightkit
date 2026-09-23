#!/usr/bin/env python3
"""Generate the built-in minimal Office templates (F-010).

Output is deterministic: fixed timestamps, fixed part order, ZIP_DEFLATED.
"""

from __future__ import annotations

import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "RightKit" / "Resources" / "Templates"

DECL = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
CT_NS = "http://schemas.openxmlformats.org/package/2006/content-types"
REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
OFFICE_REL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL = "http://schemas.openxmlformats.org/package/2006/relationships"
OFFICE_CT = "application/vnd.openxmlformats-officedocument"
A = "http://schemas.openxmlformats.org/drawingml/2006/main"
P = "http://schemas.openxmlformats.org/presentationml/2006/main"
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
S = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"


def content_types(overrides: list[tuple[str, str]]) -> str:
    items = "".join(f'<Override PartName="{p}" ContentType="{t}"/>' for p, t in overrides)
    return (
        f'<Types xmlns="{CT_NS}">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        f"{items}</Types>"
    )


def rels(items: list[tuple[str, str]]) -> str:
    """items: (type, target); ids are rId1..n in order."""
    body = "".join(
        f'<Relationship Id="rId{i}" Type="{t}" Target="{target}"/>'
        for i, (t, target) in enumerate(items, 1)
    )
    return f'<Relationships xmlns="{REL_NS}">{body}</Relationships>'


def root_rels(main: str) -> str:
    return rels([
        (f"{OFFICE_REL}/officeDocument", main),
        (f"{PKG_REL}/metadata/core-properties", "docProps/core.xml"),
        (f"{OFFICE_REL}/extended-properties", "docProps/app.xml"),
    ])


CORE = (
    '<cp:coreProperties'
    ' xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"'
    ' xmlns:dc="http://purl.org/dc/elements/1.1/"'
    ' xmlns:dcterms="http://purl.org/dc/terms/"'
    ' xmlns:dcmitype="http://purl.org/dc/dcmitype/"'
    ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>'
)
APP = (
    '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"'
    ' xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"/>'
)
DOCPROPS_CT = [
    ("/docProps/core.xml", "application/vnd.openxmlformats-package.core-properties+xml"),
    ("/docProps/app.xml", f"{OFFICE_CT}.extended-properties+xml"),
]

# --- docx ---------------------------------------------------------------

DOCX = {
    "[Content_Types].xml": content_types([
        ("/word/document.xml", f"{OFFICE_CT}.wordprocessingml.document.main+xml"),
        ("/word/styles.xml", f"{OFFICE_CT}.wordprocessingml.styles+xml"),
        ("/word/settings.xml", f"{OFFICE_CT}.wordprocessingml.settings+xml"),
        *DOCPROPS_CT,
    ]),
    "_rels/.rels": root_rels("word/document.xml"),
    "word/document.xml": (
        f'<w:document xmlns:w="{W}" xmlns:r="{OFFICE_REL}"><w:body><w:p/>'
        '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"'
        ' w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>'
        "</w:body></w:document>"
    ),
    "word/_rels/document.xml.rels": rels([
        (f"{OFFICE_REL}/styles", "styles.xml"),
        (f"{OFFICE_REL}/settings", "settings.xml"),
    ]),
    "word/styles.xml": (
        f'<w:styles xmlns:w="{W}"><w:docDefaults>'
        '<w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>'
        '<w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:rPrDefault>'
        '<w:pPrDefault><w:pPr><w:spacing w:after="160" w:line="259" w:lineRule="auto"/></w:pPr></w:pPrDefault>'
        "</w:docDefaults>"
        '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>'
        "</w:styles>"
    ),
    # compatibilityMode 15 keeps Word from opening the file in Compatibility Mode.
    "word/settings.xml": (
        f'<w:settings xmlns:w="{W}"><w:defaultTabStop w:val="720"/>'
        '<w:compat><w:compatSetting w:name="compatibilityMode"'
        ' w:uri="http://schemas.microsoft.com/office/word" w:val="15"/></w:compat>'
        "</w:settings>"
    ),
    "docProps/core.xml": CORE,
    "docProps/app.xml": APP,
}

# --- xlsx ---------------------------------------------------------------

XLSX = {
    "[Content_Types].xml": content_types([
        ("/xl/workbook.xml", f"{OFFICE_CT}.spreadsheetml.sheet.main+xml"),
        ("/xl/worksheets/sheet1.xml", f"{OFFICE_CT}.spreadsheetml.worksheet+xml"),
        ("/xl/styles.xml", f"{OFFICE_CT}.spreadsheetml.styles+xml"),
        *DOCPROPS_CT,
    ]),
    "_rels/.rels": root_rels("xl/workbook.xml"),
    "xl/workbook.xml": (
        f'<workbook xmlns="{S}" xmlns:r="{OFFICE_REL}">'
        "<bookViews><workbookView/></bookViews>"
        '<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>'
    ),
    "xl/_rels/workbook.xml.rels": rels([
        (f"{OFFICE_REL}/worksheet", "worksheets/sheet1.xml"),
        (f"{OFFICE_REL}/styles", "styles.xml"),
    ]),
    "xl/worksheets/sheet1.xml": (
        f'<worksheet xmlns="{S}" xmlns:r="{OFFICE_REL}"><dimension ref="A1"/><sheetData/></worksheet>'
    ),
    "xl/styles.xml": (
        f'<styleSheet xmlns="{S}">'
        '<fonts count="1"><font><sz val="11"/><name val="Calibri"/><family val="2"/></font></fonts>'
        '<fills count="2"><fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill></fills>'
        '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        '<dxfs count="0"/>'
        '<tableStyles count="0" defaultTableStyle="TableStyleMedium2" defaultPivotStyle="PivotStyleLight16"/>'
        "</styleSheet>"
    ),
    "docProps/core.xml": CORE,
    "docProps/app.xml": APP,
}

# --- pptx ---------------------------------------------------------------

PNS = f'xmlns:a="{A}" xmlns:r="{OFFICE_REL}" xmlns:p="{P}"'
EMPTY_TREE = (
    '<p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>'
    '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/>'
    '<a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree>'
)


def run_props(size: int, font: str) -> str:
    return (
        f'<a:defRPr sz="{size}" kern="1200"><a:solidFill><a:schemeClr val="tx1"/></a:solidFill>'
        f'<a:latin typeface="+{font}-lt"/><a:ea typeface="+{font}-ea"/><a:cs typeface="+{font}-cs"/></a:defRPr>'
    )


def solid(mods: str = "") -> str:
    return f'<a:solidFill><a:schemeClr val="phClr">{mods}</a:schemeClr></a:solidFill>'


def grad(stops: list[str]) -> str:
    gs = "".join(
        f'<a:gs pos="{pos}"><a:schemeClr val="phClr">{m}</a:schemeClr></a:gs>'
        for pos, m in zip((0, 50000, 100000), stops)
    )
    return f'<a:gradFill rotWithShape="1"><a:gsLst>{gs}</a:gsLst><a:lin ang="5400000" scaled="0"/></a:gradFill>'


def line(w: int) -> str:
    return (
        f'<a:ln w="{w}" cap="flat" cmpd="sng" algn="ctr">{solid()}'
        '<a:prstDash val="solid"/><a:miter lim="800000"/></a:ln>'
    )


def srgb(name: str, value: str) -> str:
    return f'<a:{name}><a:srgbClr val="{value}"/></a:{name}>'


THEME = (
    f'<a:theme xmlns:a="{A}" name="Office Theme"><a:themeElements>'
    '<a:clrScheme name="Office">'
    '<a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>'
    '<a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>'
    + srgb("dk2", "44546A") + srgb("lt2", "E7E6E6")
    + srgb("accent1", "4472C4") + srgb("accent2", "ED7D31") + srgb("accent3", "A5A5A5")
    + srgb("accent4", "FFC000") + srgb("accent5", "5B9BD5") + srgb("accent6", "70AD47")
    + srgb("hlink", "0563C1") + srgb("folHlink", "954F72")
    + "</a:clrScheme>"
    '<a:fontScheme name="Office">'
    '<a:majorFont><a:latin typeface="Calibri Light"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>'
    '<a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont>'
    "</a:fontScheme>"
    '<a:fmtScheme name="Office">'
    "<a:fillStyleLst>"
    + solid()
    + grad([
        '<a:lumMod val="110000"/><a:satMod val="105000"/><a:tint val="67000"/>',
        '<a:lumMod val="105000"/><a:satMod val="103000"/><a:tint val="73000"/>',
        '<a:lumMod val="105000"/><a:satMod val="109000"/><a:tint val="81000"/>',
    ])
    + grad([
        '<a:satMod val="103000"/><a:lumMod val="102000"/><a:tint val="94000"/>',
        '<a:satMod val="110000"/><a:lumMod val="100000"/><a:shade val="100000"/>',
        '<a:lumMod val="99000"/><a:satMod val="120000"/><a:shade val="78000"/>',
    ])
    + "</a:fillStyleLst>"
    "<a:lnStyleLst>" + line(6350) + line(12700) + line(19050) + "</a:lnStyleLst>"
    "<a:effectStyleLst>" + "<a:effectStyle><a:effectLst/></a:effectStyle>" * 3 + "</a:effectStyleLst>"
    "<a:bgFillStyleLst>"
    + solid()
    + solid('<a:tint val="95000"/><a:satMod val="170000"/>')
    + grad([
        '<a:tint val="93000"/><a:satMod val="150000"/><a:shade val="98000"/><a:lumMod val="102000"/>',
        '<a:tint val="98000"/><a:satMod val="130000"/><a:shade val="90000"/><a:lumMod val="103000"/>',
        '<a:shade val="63000"/><a:satMod val="120000"/>',
    ])
    + "</a:bgFillStyleLst></a:fmtScheme>"
    "</a:themeElements><a:objectDefaults/><a:extraClrSchemeLst/></a:theme>"
)

PPTX = {
    "[Content_Types].xml": content_types([
        ("/ppt/presentation.xml", f"{OFFICE_CT}.presentationml.presentation.main+xml"),
        ("/ppt/slideMasters/slideMaster1.xml", f"{OFFICE_CT}.presentationml.slideMaster+xml"),
        ("/ppt/slideLayouts/slideLayout1.xml", f"{OFFICE_CT}.presentationml.slideLayout+xml"),
        ("/ppt/slides/slide1.xml", f"{OFFICE_CT}.presentationml.slide+xml"),
        ("/ppt/theme/theme1.xml", f"{OFFICE_CT}.theme+xml"),
        ("/ppt/presProps.xml", f"{OFFICE_CT}.presentationml.presProps+xml"),
        ("/ppt/viewProps.xml", f"{OFFICE_CT}.presentationml.viewProps+xml"),
        ("/ppt/tableStyles.xml", f"{OFFICE_CT}.presentationml.tableStyles+xml"),
        *DOCPROPS_CT,
    ]),
    "_rels/.rels": root_rels("ppt/presentation.xml"),
    "ppt/presentation.xml": (
        f'<p:presentation {PNS} saveSubsetFonts="1">'
        '<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>'
        '<p:sldIdLst><p:sldId id="256" r:id="rId2"/></p:sldIdLst>'
        '<p:sldSz cx="12192000" cy="6858000"/><p:notesSz cx="6858000" cy="9144000"/>'
        '<p:defaultTextStyle><a:defPPr><a:defRPr lang="en-US"/></a:defPPr>'
        '<a:lvl1pPr marL="0" algn="l" defTabSz="914400" rtl="0" eaLnBrk="1" latinLnBrk="0" hangingPunct="1">'
        + run_props(1800, "mn")
        + "</a:lvl1pPr></p:defaultTextStyle></p:presentation>"
    ),
    "ppt/_rels/presentation.xml.rels": rels([
        (f"{OFFICE_REL}/slideMaster", "slideMasters/slideMaster1.xml"),
        (f"{OFFICE_REL}/slide", "slides/slide1.xml"),
        (f"{OFFICE_REL}/presProps", "presProps.xml"),
        (f"{OFFICE_REL}/viewProps", "viewProps.xml"),
        (f"{OFFICE_REL}/theme", "theme/theme1.xml"),
        (f"{OFFICE_REL}/tableStyles", "tableStyles.xml"),
    ]),
    "ppt/slideMasters/slideMaster1.xml": (
        f"<p:sldMaster {PNS}>"
        '<p:cSld><p:bg><p:bgRef idx="1001"><a:schemeClr val="bg1"/></p:bgRef></p:bg>'
        + EMPTY_TREE
        + "</p:cSld>"
        '<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2"'
        ' accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6"'
        ' hlink="hlink" folHlink="folHlink"/>'
        '<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>'
        "<p:txStyles>"
        '<p:titleStyle><a:lvl1pPr algn="l" defTabSz="914400" rtl="0" eaLnBrk="1" latinLnBrk="0" hangingPunct="1">'
        '<a:lnSpc><a:spcPct val="90000"/></a:lnSpc><a:spcBef><a:spcPct val="0"/></a:spcBef><a:buNone/>'
        + run_props(4400, "mj")
        + "</a:lvl1pPr></p:titleStyle>"
        '<p:bodyStyle><a:lvl1pPr marL="228600" indent="-228600" algn="l" defTabSz="914400" rtl="0"'
        ' eaLnBrk="1" latinLnBrk="0" hangingPunct="1">'
        '<a:lnSpc><a:spcPct val="90000"/></a:lnSpc><a:spcBef><a:spcPts val="1000"/></a:spcBef>'
        '<a:buFont typeface="Arial"/><a:buChar char="&#8226;"/>'
        + run_props(2800, "mn")
        + "</a:lvl1pPr></p:bodyStyle>"
        '<p:otherStyle><a:defPPr><a:defRPr lang="en-US"/></a:defPPr>'
        '<a:lvl1pPr marL="0" algn="l" defTabSz="914400" rtl="0" eaLnBrk="1" latinLnBrk="0" hangingPunct="1">'
        + run_props(1800, "mn")
        + "</a:lvl1pPr></p:otherStyle>"
        "</p:txStyles></p:sldMaster>"
    ),
    "ppt/slideMasters/_rels/slideMaster1.xml.rels": rels([
        (f"{OFFICE_REL}/slideLayout", "../slideLayouts/slideLayout1.xml"),
        (f"{OFFICE_REL}/theme", "../theme/theme1.xml"),
    ]),
    "ppt/slideLayouts/slideLayout1.xml": (
        f'<p:sldLayout {PNS} type="blank" preserve="1"><p:cSld name="Blank">{EMPTY_TREE}</p:cSld>'
        "<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>"
    ),
    "ppt/slideLayouts/_rels/slideLayout1.xml.rels": rels([
        (f"{OFFICE_REL}/slideMaster", "../slideMasters/slideMaster1.xml"),
    ]),
    "ppt/slides/slide1.xml": (
        f"<p:sld {PNS}><p:cSld>{EMPTY_TREE}</p:cSld>"
        "<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>"
    ),
    "ppt/slides/_rels/slide1.xml.rels": rels([
        (f"{OFFICE_REL}/slideLayout", "../slideLayouts/slideLayout1.xml"),
    ]),
    "ppt/theme/theme1.xml": THEME,
    "ppt/presProps.xml": f"<p:presentationPr {PNS}/>",
    "ppt/viewProps.xml": (
        f"<p:viewPr {PNS}><p:normalViewPr><p:restoredLeft sz=\"15620\"/><p:restoredTop sz=\"94660\"/>"
        '</p:normalViewPr><p:gridSpacing cx="76200" cy="76200"/></p:viewPr>'
    ),
    "ppt/tableStyles.xml": f'<a:tblStyleLst xmlns:a="{A}" def="{{5C22544A-7EE6-4342-B048-85BDC9FD1C3A}}"/>',
    "docProps/core.xml": CORE,
    "docProps/app.xml": APP,
}


def write(path: Path, parts: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w") as zf:
        for name, xml in parts.items():  # dict order = zip order; [Content_Types].xml first
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 0
            info.external_attr = 0
            zf.writestr(info, (DECL + xml).encode("utf-8"))


def main() -> None:
    for ext, parts in (("docx", DOCX), ("xlsx", XLSX), ("pptx", PPTX)):
        target = OUT / f"Template.{ext}"
        write(target, parts)
        print(f"wrote {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
