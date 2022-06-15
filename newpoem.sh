
#! /bin/bash

PROGNAME=$0
COMMIT_AUTO_AUTHOR="newpoem <newpoem@localhost>"
CACHE_DIR="${HOME}/.cache/newpoem-data"
PKG_PLACEHOLDER="<PACKAGE-NAME>"

usage(){
    echo "USAGE: $PROGNAME <package-name>"
    exit
}

portable_sed(){
    if [[ $(uname -a | grep -oic "Linux") -gt 0 ]];then
        sed -i -e "s/$1/$2/" "$3"
    else
        sed -i '' -e "s/$1/$2/" "$3"
    fi
}

change_default_poetry_versioning(){
    echo " * (sed) change version to 0.0.1 everywhere (we're bumping later)"
    portable_sed '^version = ".*"$' 'version = "0.0.1"' pyproject.toml
    portable_sed '^__version__ = .*$' '__version__ = "0.0.1"' "${PKG_NAME}/__init__.py"
}

create_structure(){
    echo " * (poetry) create new package structure at ${PKG_NAME}"
    poetry new "$PKG_NAME"
    cd "$PKG_NAME" || exit
    change_default_poetry_versioning
}

add_dev_dependencies(){
    echo " * (poetry/pip) upgrade pip"
    poetry run python3 -m pip install --upgrade pip

    echo " * (poetry/pip) install optional dev tools"
    poetry run python3 -m pip install --upgrade ipython mypy
    echo " * (poetry/pip) install and add dev tools to poetry.lock"
    poetry add --dev \
        pytest \
        pytest-cov \
        pytest-flakes \
        black \
        commitizen \
        pre-commit
}

update_pyproject_toml(){
    echo " * (cat/sed): update pyproject.toml"
    cat "${CACHE_DIR}/pyproject-devtools.toml" >> pyproject.toml
    portable_sed "${PKG_PLACEHOLDER}" "${PKG_NAME}" pyproject.toml
}

update_project_readme(){
    echo " * (cp/sed): update README.md"
    cp "${CACHE_DIR}/README.md" ./README.md
    portable_sed "${PKG_PLACEHOLDER}" "${PKG_NAME}" README.md
    rm README.rst
}

update_project_license(){
    echo " * (cp/sed): update LICENSE.md"
    cp "${CACHE_DIR}/LICENSE.md" .
    YEAR=$(date "+%Y")
    echo -n " + What full name should be on the MIT license?: "
    read -r ans

    portable_sed "\[year\]" "$YEAR" LICENSE.md
    portable_sed "\[fullname\]" "$ans" LICENSE.md
}

add_project_metadata(){
    update_pyproject_toml
    update_project_readme
    update_project_license
    echo " * (cp): copy a standard .gitignore"
    cp "${CACHE_DIR}/.gitignore" ./.gitignore
}

init_git(){
    echo " * (git) set up git repo, add metadata"
    git init
    git add README.md LICENSE.md .gitignore
    git commit \
        --message "chore: initial commit" \
        --author "${COMMIT_AUTO_AUTHOR}"

    git add pyproject.toml poetry.lock
    git commit \
        --message "build: add pyproject.toml and poetry.lock" \
        --author "${COMMIT_AUTO_AUTHOR}"
}

commit_skeleton_code(){
    echo " * (git) commit basic code structure"
    git add "${PKG_NAME}/*" tests/*
    git commit \
        --message "feat: add minimal code and tests" \
        --author "${COMMIT_AUTO_AUTHOR}"
}

add_precommit_config(){
    echo " * (pre-commit/git) set up pre-commit, put in git"
    cp "${CACHE_DIR}/.pre-commit-config.yaml" .
    poetry run pre-commit install

    git add .pre-commit-config.yaml
    git commit \
        --message "ci: set up pre-commit" \
        --author "${COMMIT_AUTO_AUTHOR}"
}

if [[ -z $1 ]];then
    usage
fi
PKG_NAME=$1

PKG_NAME=${PKG_NAME/-/_}

echo " + I will attempt to create a sensible starting workspace at ${PKG_NAME}"
echo -n " + Proceed? [y/n]: "
read -r -n1 ans
echo ""
if [[ $ans != "y" ]];then
  echo " + Stopping now."
  exit
fi

echo " + Okay, let's go!"
printf %80s | tr " " "-"
echo ""

create_structure
add_dev_dependencies
add_project_metadata
init_git
commit_skeleton_code
add_precommit_config
bump-it-all

#git init
#git checkout -b dev
