#! /bin/bash

# asdf
echo "Updating tool versions..."
task tool-versions:upgrade
echo "Initialising asdf..."
asdf install

# trunk
echo "Initialising trunk..."
trunk init --lock
trunk config share
tag=$(gh api -H "Accept: application/vnd.github+json" repos/aps831/trunk-io-plugins/releases/latest | jq .tag_name -r)
trunk plugins add --id aps831 https://github.com/aps831/trunk-io-plugins "${tag}"
trunk actions enable commit-branch
trunk actions enable commitizen-prompt-conventional
trunk actions enable commitizen-tools-check
trunk actions enable hardcoding-check
trunk actions enable templated-output-check
trunk actions enable wip-check
trunk upgrade

# github
echo "Initialising github..."
isPrivate=$(gh repo view --json isPrivate --jq '.isPrivate')
nameWithOwner=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
owner=$(gh repo view --json owner --jq '.owner.login')
repo=$(gh repo view --json name --jq '.name')
branch=$(git rev-parse --abbrev-ref HEAD)

rm -rf .github
cp -r github-private .github
if [[ ${isPrivate} == "false" ]]; then
  cp -rT github-public .github
fi
rm -rf github-private
rm -rf github-public

gh repo set-default
gh repo edit --delete-branch-on-merge
gh repo edit --enable-auto-merge=false
gh repo edit --enable-merge-commit=false
gh repo edit --enable-rebase-merge
gh repo edit --enable-squash-merge=false
gh repo edit --allow-update-branch
gh repo edit --enable-discussions=false
gh repo edit --enable-projects=false
gh repo edit --enable-wiki=false
# TODO gh repo edit -- <prevent push multiple branches> See #1
gh api --method PUT -H "Accept: application/vnd.github+json" "/repos/${nameWithOwner}/vulnerability-alerts"
gh api --method PUT -H "Accept: application/vnd.github+json" "/repos/${nameWithOwner}/automated-security-fixes"
gh api --method PUT -H "Accept: application/vnd.github+json" "/repos/${nameWithOwner}/actions/permissions/workflow" -f default_workflow_permissions='read' -F can_approve_pull_request_reviews=true
gh label create github_actions --description "Update to Github actions" --color 0E8A16
gh label create dependencies --description "Update to dependencies" --color D4C5F9
gh label create no_combine_prs --description "Prevent PR being combined into a mult-commit PR" --color FBCA04
gh label create no_ci_cd_run --description "Do not run Github actions" --color 165639
gh label create stale --description "Stale issue or PR" --color BFD4F2

if [[ ${isPrivate} == "false" ]]; then
  # MIT Licence
  wget -q -O LICENCE.md "https://raw.githubusercontent.com/IQAndreas/markdown-licenses/master/mit.md"
  # Advanced security
  echo '{"security_and_analysis":{"secret_scanning":{"status":"enabled"}}}' | gh api --method PATCH -H "Accept: application/vnd.github+json" "/repos/${nameWithOwner}" --input - >/dev/null 2>&1
  echo '{"security_and_analysis":{"advanced_security":{"status":"enabled"}}}' | gh api --method PATCH -H "Accept: application/vnd.github+json" "/repos/${nameWithOwner}" --input - >/dev/null 2>&1
  # Branch protection
  echo '{"required_status_checks":null,"enforce_admins":true,"required_pull_request_reviews":null,"restrictions":null,"required_linear_history":true,"allow_fork_syncing":false}' | gh api --method PUT -H "Accept: application/vnd.github+json" "https://api.github.com/repos/${nameWithOwner}/branches/${branch}/protection" --input - >/dev/null 2>&1
fi

export OWNER=${owner}
export REPO=${repo}
TMPFILE=$(mktemp)
envsubst <.github/workflows/bitbucket-mirror.yaml >"${TMPFILE}"
mv "${TMPFILE}" .github/workflows/bitbucket-mirror.yaml

# readme
cat README.md
echo "# ${repo}" >README.md

# remove init script
rm "$0"
