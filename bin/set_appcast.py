#!/usr/local/bin/python2

# pip2 install requests
# pip2 install Markdown

# We use python2 of brew due to some pip packages.

import os
import io
import sys
import subprocess
import requests
import json
import markdown
from datetime import datetime
from string import Template

SIGN_UPDATE = './bin/sign_update'
PRIVATE_KEY_PATH = os.path.expanduser('~/.local/secrets/sparkle_priv.pem')
GITHUB_TOKEN_PATH = os.path.expanduser('~/.local/secrets/github.qvacua.release.token')

file_path = sys.argv[1]
bundle_version = sys.argv[2]
marketing_version = sys.argv[3]
tag_name = sys.argv[4]
is_snapshot = True if len(sys.argv) > 5 and sys.argv[5] == "true" else False

file_size = os.stat(file_path).st_size
file_signature = subprocess.check_output([SIGN_UPDATE, file_path, PRIVATE_KEY_PATH]).strip()

appcast_template_file = open('resources/appcast_template.xml', 'r')
appcast_template = Template(appcast_template_file.read())
appcast_template_file.close()

token_file = open(GITHUB_TOKEN_PATH, 'r')
token = token_file.read().strip()
token_file.close()

release_response = requests.get('https://api.github.com/repos/qvacua/vimr/releases/tags/{0}'.format(tag_name),
                                params={'access_token': token})
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
    file_length=file_size,
    signature=file_signature
)

appcast_file_name = 'appcast_snapshot.xml' if is_snapshot else 'appcast.xml'

with io.open('build/Build/Products/Release/{0}'.format(appcast_file_name), 'w+') as appcast_file:
    appcast_file.write(appcast)
