Email - use email for default git

# Install

`ssh-keygen -t ed25519`
Add `cat .ssh/id_ed25519.pub` to github
`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:$GITHUB_USERNAME/dotfiles.git`
