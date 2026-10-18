# DoniApp — GitHub Actions IPA starter

A minimal SwiftUI iOS app and GitHub Actions workflow that builds an **unsigned IPA**.

## Build
1. Create a new GitHub repository named `DONIAPP`.
2. Upload the contents of this folder to the repository root (including the hidden `.github` folder).
3. Open the repository's **Actions** tab.
4. If Actions is enabled, run **Build DoniApp IPA** using **Run workflow**, or push a commit to `main`.
5. When the run succeeds, open the run and download the `DoniApp-unsigned-IPA` artifact.

## Important
The IPA produced here is unsigned. It is useful to verify the build and obtain the app bundle, but it cannot normally be installed directly on an iPhone. Installation requires appropriate signing/provisioning. This workflow does not use an Apple Developer account or signing secrets.
