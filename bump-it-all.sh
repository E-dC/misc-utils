#! /bin/bash

portable_sed(){
    if [[ $(uname -a | grep -oic "Linux") -gt 0 ]];then
        sed -i -e "s/$1/$2/" "$3"
    else
        sed -i '' -e "s/$1/$2/" "$3"
    fi
}

ask_confirmation(){
    echo -n " + Proceed? [y/n]: "
    read -r -n1 ans
    echo ""
    if [[ $ans != "y" ]];then
      echo " + Stopping now."
      exit
    fi
}

check_git_repo_is_clean(){
    CHANGES_DETECTED=$(git status -s | egrep -c '^ ?[MADRC] ')
    if [[ ${CHANGES_DETECTED} -gt 0 ]];then
        echo " + It looks like there are uncommitted changes in your repo"
        echo " + I won't bump."
        exit
    fi
    echo " + Git repo seems clean"
}

find_tag_to_create(){
    DRY_RUN=$(cz bump --dry-run --yes 2>&1)
    INCREMENT=$(echo "${DRY_RUN}" | grep -Poi '^(increment detected: )\K(MAJOR|MINOR|PATCH|None)$')
    echo " + Found increment: ${INCREMENT}"

    if [[ $INCREMENT == "None" ]];then
        echo " + No version change needed"
        exit
    fi
    TAG_TO_CREATE=$(echo "$DRY_RUN" | grep -Po '(tag to create: )\K([0-9]+\.[0-9]+\.[0-9]+)')
}

find_additional_info(){
    PKG_NAME=$(grep -C 3 '\[tool\.poetry\]' pyproject.toml | grep -Po '^(name = ")\K(.*)"$' - | sed 's/"//g')
    CURRENT_VERSION=$(grep -C 3 '\[tool\.poetry\]' pyproject.toml | grep -Po '^(version = ")\K(.*)"$' - | sed 's/"//g')
    INIT_FILE="${PKG_NAME}/__init__.py"
}

summarise_upcoming_changes(){
    echo -n " + Bumping ${PKG_NAME}: "
    echo "${CURRENT_VERSION} -> ${TAG_TO_CREATE}"
    echo " + I will change:"
    echo "   * pyproject.toml (poetry)"
    echo "   * pyproject.toml (commitizen)"
    if [[ -e ${INIT_FILE} ]];then
        echo "   * ${INIT_FILE} (code)"
    fi
    echo " + I will also create a new git tag and update CHANGELOG.md"
    ask_confirmation
}

apply_changes(){
    if [[ -e ${INIT_FILE} ]];then
        portable_sed \
            '^__version__ = .*$' \
            '__version__ = "${TAG_TO_CREATE}"' \
            "${INIT_FILE}"
        git add "${INIT_FILE}"
    else
        echo " + No ${INIT_FILE} found, leaving code alone."
    fi
    poetry version "${TAG_TO_CREATE}"
    git add pyproject.toml
    cz bump --changelog
}


echo " + Starting bumping process"
check_git_repo_is_clean
find_tag_to_create # TAG_TO_CREATE is now available
find_additional_info # PKG_NAME, CURRENT_VERSION and INIT_FILE are now available
summarise_upcoming_changes
apply_changes
echo " + Done."
