module.exports = {
  branches: ["main"],
  repositoryUrl: "https://github.com/d9007604265/sre-work-space",
  plugins: [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    ["@semantic-release/changelog", { changelogFile: "CHANGELOG.md" }],
    ["@semantic-release/git", { 
      assets: ["CHANGELOG.md", "VERSION"], 
      message: "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}" 
    }],
    "@semantic-release/github"
  ]
};
