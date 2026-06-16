#!/usr/bin/env python3
"""Package and upload the addon to CurseForge via their upload API."""
import json, os, subprocess, sys, urllib.request

API_KEY    = os.environ["CF_API_KEY"]
REF_NAME   = os.environ.get("GITHUB_REF_NAME", "v1.0.0")
PROJECT_ID = "1547500"
ZIP_PATH   = f"dist/ActionBarStorage-{REF_NAME}.zip"

# Fetch CurseForge game version list
req = urllib.request.Request(
    "https://wow.curseforge.com/api/game/versions",
    headers={"X-Api-Token": API_KEY},
)
with urllib.request.urlopen(req) as resp:
    versions = json.load(resp)

wow12 = [v for v in versions if "12." in v.get("name", "")]
print(f"12.x versions found: {wow12}")

match = next((v for v in versions if v.get("name") == "12.0.7"), None)
if not match:
    match = next((v for v in versions if v.get("name", "").startswith("12.0.")), None)
if not match:
    print("ERROR: No WoW 12.0.x version found. All versions:")
    for v in sorted(versions, key=lambda x: x.get("id", 0)):
        print(f"  id={v.get('id'):>6}  typeID={v.get('gameVersionTypeID'):>4}  name={v.get('name')}")
    sys.exit(1)

print(f"Using: {match}")

metadata = json.dumps({
    "changelog":     open("CHANGELOG.md").read(),
    "changelogType": "markdown",
    "displayName":   REF_NAME,
    "gameVersions":  [match["id"]],
    "releaseType":   "release",
})
with open("/tmp/cf_meta.json", "w") as f:
    f.write(metadata)

result = subprocess.run(
    ["curl", "-s",
     "-H", f"X-Api-Token: {API_KEY}",
     "-F", "metadata=</tmp/cf_meta.json",
     "-F", f"file=@{ZIP_PATH}",
     f"https://wow.curseforge.com/api/projects/{PROJECT_ID}/upload-file"],
    capture_output=True, text=True,
)
print(f"CurseForge response: {result.stdout}")

if result.returncode != 0:
    print(f"curl error: {result.stderr}", file=sys.stderr)
    sys.exit(1)

response = json.loads(result.stdout)
if "errorCode" in response:
    print(f"CurseForge API error: {response}", file=sys.stderr)
    sys.exit(1)

print(f"Uploaded successfully. CurseForge file ID: {response.get('id')}")
