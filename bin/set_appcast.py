#!/usr/bin/env python3

# pip3 install requests
# pip3 install Markdown

# We use python of brew due to some pip packages.

import io
import json
import subprocess
import sys
from datetime import datetime
from string import Template

import markdown
import requests

SIGN_UPDATE = './build/SourcePackages/artifacts/sparkle/bin/sign_update'

file_path = sys.argv[1]
bundle_version = sys.argv[2]
marketing_version = sys.argv[3]
tag_name = sys.argv[4]
is_snapshot = True if len(sys.argv) > 5 and sys.argv[5] == "true" else False

file_signature = subprocess.check_output([SIGN_UPDATE, file_path]).decode('utf-8').strip()

appcast_template_file = open('resources/appcast_template.xml', 'r')
appcast_template = Template(appcast_template_file.read())
appcast_template_file.close()

release_response = requests.get('https://api.github.com/repos/qvacua/vimr/releases/tags/{0}'.format(tag_name))
release_json = json.loads(release_response.content)

title = release_json['name']
download_url = release_json['assets'][0]['browser_download_url']
release_notes_url = release_json['html_url']
release_notes = release_json['body']

appcast = appcast_template.substitute(
    title=title,
    release_notes=markdown.markdown(release_notes),
    release_notes_link=release_notes_url,
    publication_date=datetime.now().isoformat(),
    file_url=download_url,
    bundle_version=bundle_version,
    marketing_version=marketing_version,
    signature_output=file_signature
)

appcast_file_name = 'appcast_snapshot.xml' if is_snapshot else 'appcast.xml'

with io.open('build/Build/Products/Release/{0}'.format(appcast_file_name), 'w+') as appcast_file:
    appcast_file.write(appcast)
