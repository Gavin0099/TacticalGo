"""Bind a copied device harness to the actual signed products, not cached M3 metadata."""
import hashlib,json,os,pathlib,plistlib
R=pathlib.Path(__file__).resolve().parents[1];P=R/'ios/Build/Products';D=R/os.environ.get('HERO_BODY_DEVICE_EVIDENCE','artifacts/ios/anim-warrior-rogue-01')
x=plistlib.loads((P/'TacticalGo_iphoneos26.5-arm64.xctestrun').read_bytes())
t=x['TacticalGoUITests'];host=P/'Debug-iphoneos/TacticalGoUITests-Runner.app'
actual=plistlib.loads((host/'Info.plist').read_bytes())['CFBundleIdentifier']
app=plistlib.loads((P/'Debug-iphoneos/TacticalGo.app/Info.plist').read_bytes())['CFBundleIdentifier']
assert app == 'com.tacticalgo.prototype.herobody' and actual == app+'.xctrunner'
old=t['TestHostBundleIdentifier'];t['TestHostBundleIdentifier']=actual
for k,v in list(t.items()):
 if isinstance(v,str):t[k]=v.replace('__TESTROOT__',str(P))
(D/'HeroBodyDevice.xctestrun').write_bytes(plistlib.dumps(x))
binary=host/'PlugIns/TacticalGoUITests.xctest/TacticalGoUITests'
(D/'device-harness.json').write_text(json.dumps({'oldCachedHost':old,'actualProductHost':actual,'targetApp':app,'testBinarySHA256':hashlib.sha256(binary.read_bytes()).hexdigest(),'reason':'Shared Build/Products xctestrun retained old M3 host ID despite new signed products. A zero-tests exit was rejected; copy points to actual products without changing source/tests.'},indent=2)+'\n')
print(actual,app)
