## 1. Purpose of this PR
- [ ] 🐛 Bug fix (corrects false positive/false negative or broken behavior)
- [ ] ✨ New control / attack-scenario coverage
- [ ] 🔧 Control logic update (existing Rego behavior change)
- [ ] 🧪 Test-only change (`*_test.rego` only, no production rule changes)
- [ ] 🗂️ Metadata / mapping update (`metadata.yaml` and/or mapping CSV)
- [ ] 📝 Documentation/content update (README, threat-model docs, images)
- [ ] ♻️ Refactor (no functional behavior changes)
- [ ] ⚙️ Build / configuration / automation change

## 2. Description

## 3. Scope
- Cloud / Service: `gcp/bigquery` (example)
- Control ID(s): `Bigquery.C123` (example)
- Variant(s): `universal` / `allowlist` / `denylist`

## 3. Description

## 4. Related Issue (Leave blank if not applicable)
Closes #

## 5. Testing (OPA)
- [ ] I used the repo-bundled OPA (`.\opa.exe` version 0.5.8)
- [ ] I ran tests for the changed control/variant(s)

```powershell
# Example (update to your control/variant)
.\opa.exe test .\gcp\bigquery\controls\Bigquery.C123\universal -v
```

## 6. Checklist
- [ ] I have performed a self-review
- [ ] I added or updated tests (`*_test.rego`) as needed
- [ ] If I ran a folder sweep, I used `.\utils\CCRPackageRename.ps1` to avoid package collisions
- [ ] Package header is `package wiz` for Wiz compatibility in committed Rego
- [ ] Mapping CSV updated if control metadata or mappings changed
