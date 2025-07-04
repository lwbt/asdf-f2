#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/ayoisaiah/f2"
TOOL_NAME="f2"
TOOL_TEST="f2 --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --heads --tags $GH_REPO |
		grep refs/tags |
		cut -d '/' -f 3 |
		grep -v '\^{}' |
		sed -E 's/^(v)([0-9]+\.[0-9]+\.[0-9]+)$/\2/'
}

list_all_versions() {
	list_github_tags
}

download_release() {
	local version filename url
	version="$1"
	filename="$2"
	architecture="$(uname -m)"
	os="$(uname | tr '[:upper:]' '[:lower:]')"

#	if [ "$os" = "darwin" ]; then
#		os="macos"
#	fi

#	if [ "$architecture" = "arm64" ]; then
#		architecture="aarch64"
#	fi

	if [ "$architecture" = "x86_64" ]; then
		architecture="amd64"
	fi
 
	url="$GH_REPO/releases/download/v${version}/f2_${version}_${os}_${architecture}.tar.gz"

	echo "* Downloading $TOOL_NAME release $version..."
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	)
#	) || (
#		rm -rf "$install_path"
#		fail "An error occurred while installing $TOOL_NAME $version."
#	)
}
