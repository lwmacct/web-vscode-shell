
__git_push() {
    git rm -r --cached ~
    git add ~
    git commit -m "init"
    git branch -M main
    git push -f -u origin main
}

__git_push
