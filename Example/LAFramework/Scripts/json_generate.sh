#!/bin/bash

#  generate.sh
#  LAFramework
#
#  Created by LakeR on 7/28/16.
#  Copyright (c) 2016 LakeR inc. All rights reserved.

# TODO: this could probably be folded into the Perl script

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

protoRegex="#undef\s*__CLASS__\s*#define\s*__CLASS__\s*(\w+)"

find "${SRCROOT}" -type f -name "*.h" -print0 | while IFS= read -r -d '' file; do
contents=$(<"${file}")

if [[ ${contents} =~ $protoRegex ]]; then
echo "${file} matches"
echo "class name: ${BASH_REMATCH[1]}"

perl "${DIR}/json_parse.pl" "${file}" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
done

echo "json proto generation finished"