# -*- mode: python ; coding: utf-8 -*-

import sys
from pathlib import Path
from PyInstaller.utils.hooks import collect_submodules

# 🧠 Define your source script
main_script = 'main.py'

# 📁 Adjust these paths to your actual venv site-packages
venv_site_packages = Path("venv/Lib/site-packages")

# 📦 Add data folders for models and resources
datas = [
    ('.allears_config.json', '.'),
    ('C:/Users/ASUS/AppData/Roaming/nltk_data/tokenizers/punkt', 'nltk_data/tokenizers/punkt'),
    
    ('core', 'core'),
    ('routers', 'routers'),

    # 📂 Memory folder (dynamic JSONL memory)
    ('memory', 'memory'),
]

# 🧩 Hidden imports for ML frameworks
hiddenimports = [
    "torch",
    "transformers",
    "sentence_transformers",
    "keybert",
    "sklearn.utils._typedefs",
] + collect_submodules("transformers.models") + collect_submodules("nltk")

# 🔧 Build block
a = Analysis(
    [main_script],
    pathex=[],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
    noarchive=False
)

# ⛓️ Build the executable
pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='AllEarsServer',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,
    disable_windowed_traceback=False
)

# 📂 Bundle into dist/
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    name='AllEarsServer'
)
