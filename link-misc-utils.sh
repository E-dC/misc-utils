#! /bin/bash

SCRIPTDIR=$(dirname $(realpath $0))

for filepath in ${SCRIPTDIR}/*.sh;do
    linkname=$(basename -s ".sh" $filepath)
    linkpath="${HOME}/bin/${linkname}"

    echo "Linking ${linkpath} to ${filepath}"
    ln -s $filepath $linkpath
done

echo "Copying newpoem-data to cache."
cp -r "${SCRIPTDIR}/newpoem-data" "${HOME}/.cache"
