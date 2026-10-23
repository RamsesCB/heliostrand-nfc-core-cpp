#!/usr/bin/env bash
# Install the NDK used by Flutter 3.47.2 before Gradle configuration.
# Retry temporary SDK download/ZIP failures rather than failing the whole build.
set -euo pipefail

ndk_version="${ANDROID_NDK_VERSION:-28.2.13676358}"
sdk_root="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "$sdk_root" || "$sdk_root" == "/" ]]; then
  echo "::error::ANDROID_HOME or ANDROID_SDK_ROOT must point to the Android SDK."
  exit 1
fi

sdkmanager="${SDKMANAGER_BIN:-$sdk_root/cmdline-tools/latest/bin/sdkmanager}"
if [[ ! -x "$sdkmanager" ]]; then
  echo "::error::Android sdkmanager not executable: $sdkmanager"
  exit 1
fi

ndk_dir="$sdk_root/ndk/$ndk_version"
ndk_is_valid() {
  [[ -f "$ndk_dir/source.properties" ]] &&
    grep -Fqx "Pkg.Revision = $ndk_version" "$ndk_dir/source.properties"
}

if ndk_is_valid; then
  echo "Android NDK $ndk_version already installed."
  exit 0
fi

for attempt in 1 2 3; do
  echo "::group::Install Android NDK $ndk_version (attempt $attempt/3)"
  # An interrupted unzip can leave a partial NDK folder.
  rm -rf -- "$ndk_dir"
  if "$sdkmanager" --sdk_root="$sdk_root" --install "ndk;$ndk_version" && ndk_is_valid; then
    echo "Android NDK $ndk_version installed and revision verified."
    echo "::endgroup::"
    exit 0
  fi
  echo "::warning::Android NDK installation attempt $attempt failed."
  echo "::endgroup::"
  if [[ "$attempt" -lt 3 ]]; then sleep $((attempt * 15)); fi
done

echo "::error::Failed to install Android NDK $ndk_version after 3 attempts."
exit 1
