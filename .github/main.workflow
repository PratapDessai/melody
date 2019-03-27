workflow "pull request" {
  resolves = [
    "lint",
    "bundlesize",
    "test",
    "canary release",
    "filter PRs",
  ]
  on = "pull_request"
}

action "filter PRs" {
  uses = "actions/bin/filter@d820d56839906464fb7a57d1b4e1741cf5183efa"
  args = "action 'opened|synchronize|reopened'"
}

action "build" {
  uses = "docker://node:8"
  args = "yarn install --frozen-lockfile --non-interactive"
  needs = ["filter PRs"]
}

action "test" {
  uses = "docker://node:8"
  needs = ["build"]
  args = "yarn run test"
}

action "lint" {
  uses = "docker://node:8"
  needs = ["build"]
  args = "yarn run lint"
}

action "bundlesize" {
  uses = "docker://node:8"
  needs = ["test"]
  args = "yarn run bundlesize"
}

action "verdaccio" {
  uses = "./actions/verdaccio"
  needs = ["test"]
  args = "-ddd"
}

action "canary release" {
  uses = "./actions/cli"
  env = {
    REGISTRY_URL = "registry.verdaccio.org"
  }
  args = "n 8 && yarn lerna publish --no-git-tag-version --no-push --no-git-reset --exact --force-publish --canary --yes --dist-tag $(git rev-parse --abbrev-ref HEAD) --preid $(git rev-parse --short HEAD) --registry https://$REGISTRY_URL"
  needs = ["verdaccio"]
}

workflow "node 6" {
  resolves = [
    "node6:test",
  ]
  on = "pull_request"
}

action "node6:build" {
  uses = "docker://node:6"
  args = "yarn install --frozen-lockfile --non-interactive"
}

action "node6:test" {
  uses = "docker://node:6"
  needs = ["node6:build"]
  args = "yarn test"
}

workflow "node 10" {
  resolves = [
    "node10:test",
  ]
  on = "pull_request"
}

action "node10:build" {
  uses = "docker://node:10"
  args = "yarn install --frozen-lockfile --non-interactive"
}

action "node10:test" {
  uses = "docker://node:10"
  needs = ["node10:build"]
  args = "yarn test"
}

workflow "node 11" {
  resolves = [
    "node11:test",
  ]
  on = "pull_request"
}

action "node11:build" {
  uses = "docker://node:11"
  args = "yarn install --frozen-lockfile --non-interactive"
}

action "node11:test" {
  uses = "docker://node:11"
  needs = ["node11:build"]
  args = "yarn test"
}

workflow "release" {
  on = "release"
  resolves = ["release:publish"]
}

action "release:authorized users only" {
  uses = "actions/bin/filter@d820d56839906464fb7a57d1b4e1741cf5183efa"
  args = ["actor", "ayusharma", "pago"]
}

action "release:build" {
  needs = ["release:authorized users only"]
  uses = "docker://node:8"
  args = "yarn install --frozen-lockfile --non-interactive"
}

action "release:test" {
  uses = "docker://node:8"
  needs = ["release:build"]
  args = "yarn test"
}

action "release: version" {
  uses = "./actions/cli"
  needs = ["release:test"]
  args = "git checkout -b $(echo $GITHUB_REF | cut -d / -f3) && yarn lerna version $(echo $GITHUB_REF | cut -d / -f3) --no-push  --yes --force-publish"
}

action "release:publish" {
  uses = "./actions/cli"
  needs = ["release: version"]
  args = "yarn lerna publish from-git --force-publish --yes --registry https://$REGISTRY_URL"
  env = {
    REGISTRY_URL = "registry.verdaccio.org"
  }
  secrets = ["REGISTRY_AUTH_TOKEN"]
}

workflow "master branch only" {
  on = "push"
  resolves = ["master:lint", "master:bundlesize", "master:release alpha"]
}

action "filter master branch" {
  uses = "actions/bin/filter@d820d56839906464fb7a57d1b4e1741cf5183efa"
  args = "branch master"
}

action "master:build" {
  uses = "docker://node:8"
  args = "yarn install --frozen-lockfile --non-interactive"
  needs = ["filter master branch"]
}

action "master:lint" {
  uses = "docker://node:8"
  needs = ["master:build"]
  args = "yarn lint"
}

action "master:test" {
  uses = "docker://node:8"
  needs = ["master:build"]
  args = "yarn test"
}

action "master:bundlesize" {
  uses = "docker://node:8"
  needs = ["master:test"]
  args = "yarn bundlesize"
}

action "master:verdaccio" {
  uses = "./actions/verdaccio"
  needs = ["master:test"]
  args = "-ddd"
}

action "master:release alpha" {
  uses = "./actions/cli"
  needs = ["master:verdaccio"]
  args = "n 8 && yarn lerna publish --no-git-tag-version --no-push --no-git-reset --exact --force-publish --canary --yes --dist-tag prerelease --registry https://$REGISTRY_URL"
}

workflow "non-master branch" {
  on = "push"
  resolves = [
    "non-master:test",
  ]
}

action "filter non-master branch" {
  uses = "actions/bin/filter@d820d56839906464fb7a57d1b4e1741cf5183efa"
  args = "not branch master"
}

action "non-master:build" {
  uses = "docker://node:8"
  args = "yarn install --frozen-lockfile --non-interactive"
  needs = ["filter non-master branch"]
}

action "non-master:test" {
  uses = "docker://node:8"
  args = "yarn test"
  needs = ["non-master:build"]
}

workflow "pull request closed" {
  on = "pull_request"
  resolves = [
    "remove dist-tag",
  ]
}

action "filter PR closed" {
  uses = "actions/bin/filter@d820d56839906464fb7a57d1b4e1741cf5183efa"
  args = "action 'closed'"
}

action "remove dist-tag" {
  uses = "./actions/cli"
  needs = ["filter PR closed"]
  args = "node bin/dist-tag-rm.js packages $(git rev-parse --abbrev-ref HEAD) https://$REGISTRY_URL"
  env = {
    REGISTRY_URL = "registry.verdaccio.org"
  }
}
