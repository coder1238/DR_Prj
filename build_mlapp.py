#!/usr/bin/env python3
"""
build_mlapp.py — Builds standard MATLAB App Designer (.mlapp) package from RetinaCareApp.m
Packaging complies with Open Packaging Conventions (OPC) and MathWorks App Designer specifications.
"""

import os
import sys
import zipfile
import datetime

def build_mlapp(source_m="RetinaCareApp.m", target_mlapp="RetinaCareApp.mlapp", screenshot_png="sample_data/patient_suresh_verma_followup.png"):
    base_dir = os.path.dirname(os.path.abspath(__file__))
    source_path = os.path.join(base_dir, source_m)
    target_path = os.path.join(base_dir, target_mlapp)
    screenshot_path = os.path.join(base_dir, screenshot_png)

    if not os.path.isfile(source_path):
        print(f"Error: Source file '{source_path}' not found.")
        sys.exit(1)

    with open(source_path, "r", encoding="utf-8") as f:
        m_code = f.read()

    document_xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="no" ?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body><w:p><w:pPr><w:pStyle w:val="code"/></w:pPr><w:r><w:t><![CDATA['
        f'{m_code}'
        ']]></w:t></w:r></w:p></w:body></w:document>'
    )

    content_types_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default ContentType="application/vnd.mathworks.matlab.appDesigner.appModel+mat" Extension="mat"/>
  <Default ContentType="image/png" Extension="png"/>
  <Default ContentType="application/vnd.openxmlformats-package.relationships+xml" Extension="rels"/>
  <Default ContentType="application/vnd.mathworks.matlab.code.document+xml;plaincode=true" Extension="xml"/>
  <Override ContentType="application/vnd.mathworks.matlab.appDesigner.appMetadata+xml" PartName="/metadata/appMetadata.xml"/>
  <Override ContentType="application/vnd.openxmlformats-package.core-properties+xml" PartName="/metadata/coreProperties.xml"/>
  <Override ContentType="application/vnd.mathworks.package.coreProperties+xml" PartName="/metadata/mwcoreProperties.xml"/>
  <Override ContentType="application/vnd.mathworks.package.corePropertiesExtension+xml" PartName="/metadata/mwcorePropertiesExtension.xml"/>
</Types>"""

    rels_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Target="matlab/document.xml" Type="http://schemas.mathworks.com/matlab/code/2013/relationships/document"/>
  <Relationship Id="rId2" Target="metadata/mwcoreProperties.xml" Type="http://schemas.mathworks.com/package/2012/relationships/coreProperties"/>
  <Relationship Id="rId3" Target="metadata/mwcorePropertiesExtension.xml" Type="http://schemas.mathworks.com/package/2014/relationships/corePropertiesExtension"/>
  <Relationship Id="rId4" Target="metadata/coreProperties.xml" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties"/>
  <Relationship Id="rId5" Target="appdesigner/appModel.mat" Type="http://schemas.mathworks.com/appDesigner/app/2014/relationships/appModel"/>
  <Relationship Id="rId6" Target="metadata/appMetadata.xml" Type="http://schemas.mathworks.com/appDesigner/app/2017/relationships/appMetadata"/>
  <Relationship Id="rId7" Target="metadata/appScreenshot.png" Type="http://schemas.mathworks.com/appDesigner/app/2017/relationships/appScreenshot"/>
  <Relationship Id="rId8" Target="metadata/appScreenshot.png" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/thumbnail"/>
</Relationships>"""

    app_metadata_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<metadata xmlns="http://schemas.mathworks.com/appDesigner/app/2017/appMetadata">
  <description>RetinaCare AI — Smart Diabetic Retinopathy Screening and Clinical Decision Support System modeled faithfully after the Stitch tele-ophthalmology web architecture.</description>
  <MLAPPVersion>2</MLAPPVersion>
  <minimumSupportedMATLABRelease>R2020b</minimumSupportedMATLABRelease>
  <screenshotMode>auto</screenshotMode>
  <uuid>d7a8e941-8f52-45e3-9821-71e84fa18c42</uuid>
  <AppType>Standard</AppType>
  <componentProducts/>
</metadata>"""

    core_properties_xml = f"""<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dcterms:created xsi:type="dcterms:W3CDTF">{datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}</dcterms:created>
  <dc:creator>RetinaCare AI Engineering Team</dc:creator>
  <dc:description>Modeled faithfully after the Stitch Project 8514012087795404150 and retinacare-ai web platform.</dc:description>
  <dcterms:modified xsi:type="dcterms:W3CDTF">{datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}</dcterms:modified>
  <dc:title>RetinaCareApp</dc:title>
  <cp:version>2.4</cp:version>
</cp:coreProperties>"""

    mwcore_properties_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<mwcoreProperties xmlns="http://schemas.mathworks.com/package/2012/coreProperties">
  <contentType>application/vnd.mathworks.matlab.app</contentType>
  <contentTypeFriendlyName>MATLAB App</contentTypeFriendlyName>
  <matlabRelease>R2024b</matlabRelease>
</mwcoreProperties>"""

    mwcore_properties_ext_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<mwcoreProperties xmlns="http://schemas.mathworks.com/package/2014/corePropertiesExtension">
  <matlabVersion>24.2.0</matlabVersion>
</mwcoreProperties>"""

    screenshot_bytes = b""
    if os.path.isfile(screenshot_path):
        with open(screenshot_path, "rb") as f:
            screenshot_bytes = f.read()

    # Re-use level-5 MAT-file or existing appModel.mat
    sample_mlapp = "/tmp/sample.mlapp"
    if os.path.isfile(sample_mlapp):
        with zipfile.ZipFile(sample_mlapp) as szf:
            app_model_mat = szf.read("appdesigner/appModel.mat")
    elif os.path.isfile(target_path):
        with zipfile.ZipFile(target_path) as ezf:
            app_model_mat = ezf.read("appdesigner/appModel.mat")
    else:
        # Fallback empty Level 5 MAT header
        header = b'MATLAB 5.0 MAT-file, Platform: GLNXA64, Created on: ' + datetime.datetime.now().ctime().encode()
        header = header.ljust(124) + b'\x00\x00\x00\x01IM'
        app_model_mat = header

    with zipfile.ZipFile(target_path, "w", compression=zipfile.ZIP_DEFLATED) as out_zf:
        out_zf.writestr("[Content_Types].xml", content_types_xml)
        out_zf.writestr("_rels/.rels", rels_xml)
        out_zf.writestr("metadata/appMetadata.xml", app_metadata_xml)
        out_zf.writestr("metadata/coreProperties.xml", core_properties_xml)
        out_zf.writestr("metadata/mwcoreProperties.xml", mwcore_properties_xml)
        out_zf.writestr("metadata/mwcorePropertiesExtension.xml", mwcore_properties_ext_xml)
        if screenshot_bytes:
            out_zf.writestr("metadata/appScreenshot.png", screenshot_bytes)
        out_zf.writestr("matlab/document.xml", document_xml)
        out_zf.writestr("appdesigner/appModel.mat", app_model_mat)

    print(f"Successfully packaged '{target_path}' ({os.path.getsize(target_path)} bytes)")

if __name__ == "__main__":
    build_mlapp()
