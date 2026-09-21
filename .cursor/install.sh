#!/usr/bin/env bash
#
# Idempotent Cloud Agent bootstrap for this PowerShell script repository.
#
# The repository is a single Windows-focused PowerShell deployment script
# (Invoke-AppDeploy.ps1). The development toolchain is therefore PowerShell 7
# (pwsh) plus the PSScriptAnalyzer module for parsing/linting the script.
#
# This script is safe to run repeatedly: each step checks for the desired
# state before doing any work.
set -euo pipefail

echo "==> Ensuring PowerShell 7 (pwsh) is installed"
if command -v pwsh >/dev/null 2>&1; then
	echo "    pwsh already installed: $(pwsh --version)"
else
	echo "    Installing PowerShell via the Microsoft apt repository"
	sudo apt-get update -qq
	sudo apt-get install -y -qq wget apt-transport-https software-properties-common >/dev/null

	# shellcheck disable=SC1091
	. /etc/os-release
	tmp_deb="$(mktemp --suffix=.deb)"
	wget -q "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" -O "${tmp_deb}"
	sudo dpkg -i "${tmp_deb}" >/dev/null 2>&1 || true
	rm -f "${tmp_deb}"

	sudo apt-get update -qq
	sudo apt-get install -y -qq powershell >/dev/null
	echo "    Installed: $(pwsh --version)"
fi

echo "==> Ensuring PSScriptAnalyzer PowerShell module is installed"
pwsh -NoProfile -Command '
	$ErrorActionPreference = "Stop"
	if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
		$v = (Get-Module -ListAvailable -Name PSScriptAnalyzer | Select-Object -First 1).Version
		Write-Host "    PSScriptAnalyzer already installed: $v"
	} else {
		Write-Host "    Installing PSScriptAnalyzer from the PowerShell Gallery"
		Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
		Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -Repository PSGallery
		$v = (Get-Module -ListAvailable -Name PSScriptAnalyzer | Select-Object -First 1).Version
		Write-Host "    Installed PSScriptAnalyzer: $v"
	}
'

echo "==> Environment ready"
