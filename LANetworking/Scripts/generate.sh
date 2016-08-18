#!/bin/bash

#  generate.sh
#  Restless
#
#  Created by Nate Petersen on 8/27/15.
#  Copyright (c) 2015 Digital Rickshaw. All rights reserved.

# TODO: this could probably be folded into the Perl script
find ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH} -name '*.laproto' -delete
CURRENT_DIR=$(pwd)
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

protoRegex="@protocol ([a-zA-Z0-9]*) <LAWebService>"

find "${SRCROOT}" -type f -name "*.h" -print0 | while IFS= read -r -d '' file; do
	contents=$(<"${file}")

	if [[ ${contents} =~ $protoRegex ]]; then
		echo "${file} matches"
		echo "Protocol name: ${BASH_REMATCH[1]}"

		perl "${DIR}/proto_parse.pl" "${file}" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
	fi
done

echo "Web service generation finished"
echo "$CURRENT_DIR"
cd $CURRENT_DIR