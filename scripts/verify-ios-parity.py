#!/usr/bin/env python3
"""Replay the immutable reviewed C# gameplay revision without touching its checkout."""
from pathlib import Path
import subprocess, tempfile, sys, shutil, os
repo = Path(__file__).resolve().parents[1]
dotnet = os.environ.get('TACTICALGO_DOTNET') or shutil.which('dotnet') or str(Path.home() / '.dotnet/dotnet')
revision = '54deef97e0fb7157b0025a7282fc2c0a448d4fb9'
out = Path(sys.argv[1] if len(sys.argv) > 1 else repo / 'artifacts/ios/playable-a0-v01').resolve()
out.mkdir(parents=True, exist_ok=True)
fixtures = repo / 'tests/ios-golden'
files = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, 'src/TacticalGo.Domain', 'tests/golden'], cwd=repo, text=True).splitlines()
with tempfile.TemporaryDirectory(prefix='tacticalgo-ios-reference-') as temp:
    temp = Path(temp)
    for filename in files:
        data = subprocess.check_output(['git', 'show', revision + ':' + filename], cwd=repo)
        target = temp / filename
        target.parent.mkdir(parents=True, exist_ok=True); target.write_bytes(data)
        if filename.endswith('.json') and filename.startswith('tests/golden/'):
            assert (fixtures / Path(filename).name).read_bytes() == data, 'Reviewed fixture changed: ' + filename
    exporter = temp / 'exporter'; exporter.mkdir()
    (exporter / 'Program.cs').write_bytes((repo / 'scripts/ios-reference-export/Program.cs').read_bytes())
    (exporter / 'Reference.csproj').write_text('<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net9.0</TargetFramework><ImplicitUsings>enable</ImplicitUsings><Nullable>enable</Nullable></PropertyGroup><ItemGroup><ProjectReference Include="../src/TacticalGo.Domain/TacticalGo.Domain.csproj" /></ItemGroup></Project>')
    subprocess.run([dotnet, 'run', '--project', str(exporter), '--', str(fixtures), str(out / 'csharp.json')], check=True)
subprocess.run(['swift', 'run', '--package-path', str(repo / 'swift/TacticalGoCore'), 'tacticalgo-golden', str(fixtures), str(out / 'swift.json')], check=True)
subprocess.run([sys.executable, str(repo / 'scripts/compare-golden.py'), str(out / 'csharp.json'), str(out / 'swift.json')], check=True)
print('Reference revision:', revision)
