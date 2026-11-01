#!/usr/bin/env python3
"""
Build the forwarding / embed layer for cauchy.math.duke.edu
Keeps the address bar showing https://sites.math.duke.edu/~rann/...
while seamlessly serving content from https://rannbar-on.com/duke/...
"""

import os
import shutil

LOCALWEBDIR = '/home/rann/src/Dukewebsite'
CAUCHY_DIR = os.path.join(LOCALWEBDIR, 'public_cauchy')

if os.path.exists(CAUCHY_DIR):
    shutil.rmtree(CAUCHY_DIR)
os.makedirs(CAUCHY_DIR, exist_ok=True)

WRAPPER_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Rann Bar-On | Duke Mathematics</title>
  <link rel="canonical" href="{target_url}">
  <style>
    html, body {{
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background-color: #0b1120;
    }}
    #duke-embed-frame {{
      border: none;
      width: 100vw;
      height: 100vh;
      display: block;
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
    }}
  </style>
</head>
<body>
  <iframe id="duke-embed-frame" src="{target_url}" allowfullscreen></iframe>
  <script>
    (function() {{
      try {{
        var path = window.location.pathname.replace(/^\\/~rann\\/?/, '');
        var search = window.location.search || '';
        var hash = window.location.hash || '';
        var defaultTarget = '{target_url}';
        if (path && path !== '{rel_path}') {{
          document.getElementById('duke-embed-frame').src = 'https://rannbar-on.com/duke/' + path + search + hash;
        }}
      }} catch(e) {{}}
    }})();
  </script>
</body>
</html>
"""

# 1. Create root index.html
with open(os.path.join(CAUCHY_DIR, 'index.html'), 'w') as f:
    f.write(WRAPPER_TEMPLATE.format(
        target_url='https://rannbar-on.com/duke/',
        rel_path=''
    ))

# 2. Create 404.html wrapper
with open(os.path.join(CAUCHY_DIR, '404.html'), 'w') as f:
    f.write(WRAPPER_TEMPLATE.format(
        target_url='https://rannbar-on.com/duke/',
        rel_path=''
    ))

# 3. Create wrappers for all key sections and course pages
pages = [
    '105lmaterials',
    'project/105lmaterials',
    '106lmaterials',
    'project/106Lmaterials',
    '218materials',
    'project/218materials',
    '218labs',
    'project/218labs',
    '218lmaterials',
    'project/218lmaterials',
    'teachingphilosophy',
    'videoproject'
]

for p in pages:
    page_dir = os.path.join(CAUCHY_DIR, p)
    os.makedirs(page_dir, exist_ok=True)
    target = f'https://rannbar-on.com/duke/{p}/'
    with open(os.path.join(page_dir, 'index.html'), 'w') as f:
        f.write(WRAPPER_TEMPLATE.format(
            target_url=target,
            rel_path=p
        ))

# 4. Copy static PDFs and assets from static/ so direct download links never break
static_dirs = [
    'classworksheets105Lpdfs',
    'classworksheets106Lpdfs',
    'labs105.2018pdfs',
    'labs106.2018pdfs',
    '105Lmaterials',
    '106Lmaterials',
    '218pdfs',
    'applets'
]

for sdir in static_dirs:
    src = os.path.join(LOCALWEBDIR, 'static', sdir)
    dst = os.path.join(CAUCHY_DIR, sdir)
    if os.path.exists(src):
        shutil.copytree(src, dst, dirs_exist_ok=True)

# Also copy static files
static_files = ['cv.pdf', 'gradescopelogin.png', 'gradescopesubresub.png', 'trigmodelsQ1answer.png']
for sfile in static_files:
    src = os.path.join(LOCALWEBDIR, 'static', sfile)
    dst = os.path.join(CAUCHY_DIR, sfile)
    if os.path.exists(src):
        shutil.copy2(src, dst)

# 5. Create .htaccess for Apache reverse proxy (with fallback to wrapper)
htaccess_content = """# Apache configuration for https://sites.math.duke.edu/~rann/
# Transparently display the new location while keeping the Duke address in the browser bar

<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /~rann/

  # If Apache mod_proxy is enabled, transparently reverse proxy
  <IfModule mod_proxy.c>
    # Do not proxy local static PDFs and images
    RewriteCond %{REQUEST_URI} !\\.(pdf|png|jpg|jpeg|gif|svg|zip)$ [NC]
    RewriteRule ^(.*)$ https://rannbar-on.com/duke/$1 [P,L]
  </IfModule>
</IfModule>

# If mod_proxy is unavailable or request 404s, route to index.html wrapper
ErrorDocument 404 /~rann/index.html
"""

with open(os.path.join(CAUCHY_DIR, '.htaccess'), 'w') as f:
    f.write(htaccess_content)

print(f'Successfully built cauchy forwarder layer in {CAUCHY_DIR}')
