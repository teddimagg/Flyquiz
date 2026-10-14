# TestFlight setup (one-time)

After this, every push to `main` lands on your iPhone through the TestFlight app about 10–20 minutes later.
You don't need a Mac: signing uses Apple's cloud-managed certificates through an App Store Connect API key.

You need a paid **Apple Developer Program** membership.

## 1. Register the bundle ID

[developer.apple.com → Identifiers → +](https://developer.apple.com/account/resources/identifiers/add/bundleId)
→ **App IDs** → **App** → Explicit Bundle ID: `is.codelab.flyquiz` → Register.

> Want a different ID? Register that one instead and set a GitHub Actions **variable** (not a secret) named `BUNDLE_ID`.

## 2. Create the app in App Store Connect

[App Store Connect → Apps → + → New App](https://appstoreconnect.apple.com/apps)
- Platform: iOS
- Name: anything unique on the App Store, e.g. *Flyquiz: Flags of the World* (the home-screen name stays "Flyquiz")
- Bundle ID: the one from step 1
- SKU: `flyquiz`

## 3. Create an API key

[App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys → +](https://appstoreconnect.apple.com/access/integrations/api)
- Name: `GitHub Actions`, Access: **Admin** (required for cloud signing)
- Download the `.p8` file. You can only download it once.
- Note the **Key ID** and the **Issuer ID** shown above the table.

## 4. Find your Team ID

[developer.apple.com → Account → Membership details](https://developer.apple.com/account#MembershipDetailsCard): the 10-character **Team ID**.

## 5. Add GitHub secrets

GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
| --- | --- |
| `ASC_KEY_ID` | Key ID from step 3 |
| `ASC_ISSUER_ID` | Issuer ID from step 3 |
| `ASC_KEY_P8` | Full text of the `.p8` file, including the `-----BEGIN PRIVATE KEY-----` lines |
| `DEVELOPMENT_TEAM` | Team ID from step 4 |

## 6. Add yourself as a tester

App Store Connect → your app → **TestFlight** → **Internal Testing** → **+** create a group, add yourself,
and leave **automatic distribution** on. Install [TestFlight](https://apps.apple.com/app/testflight/id899247664) on your iPhone and sign in with the same Apple ID.

## 7. Ship it

Push to `main`, or run the **iOS** workflow manually from the Actions tab. When the run is green, the build shows up in TestFlight once Apple finishes processing.

### Troubleshooting

- **"No Accounts" / "No signing certificate"**: the API key must have the **Admin** role.
- **"No suitable application records were found"**: step 2 hasn't been done, or the bundle ID doesn't match.
- **"The bundle version must be higher"**: build numbers come from the workflow run number. If you ever upload manually, re-run the workflow until the number is higher.
- The workflow skips the upload, with a warning, until all four secrets exist. Plain builds still run so you can see the app compile.
