#!/usr/bin/env bash

# import_ISIR_prod
# Script to fetch and fix tdaccess files for workday import
# Cian Phillips <cianphillips@gmail.com>
# to lint: shellcheck -x check_file.sh  --shell=bash

## fail if pipe returns a non-zero status
set -euo pipefail

## Script will get these reports
REPORTS=("IDSA" "IDAP" "IGCO" "IGSA" "IGSG" "ISRF" "CRPN" "CRMY" "CORE")

## Script will try these report years
YEARS=("20OP" "21OP" "22OP")

###############################################
# Set up other variables for this environment #
###############################################
## Originally set up to store the files in the TDAccess install directory
## Kind of messy, but it's what people are used to
TDHOME="${HOME}/fa.dir/TDAccess3.3.0"

## Full path to binary, means we don't have to rely on environment variables
TDCLIENT="${TDHOME}/tdclientc"

## Location where we store files for pickup by Workday (via sftp)
INCOMING_HOME="${TDHOME}/incoming"

## Location where we back up the files before Workday grabs and deletes them
INCOMING_BAK="${TDHOME}/incoming_bak"

## Script will get these types of reports
REPORT_TYPE="ISR_"

FILE_LIST=""

## Original script relied on being run from the TDClient folder
cd ${TDHOME}

## Load shared libraries compiled during TDAccess installation process
export LD_LIBRARY_PATH=${TDHOME}:$LD_LIBRARY_PATH


##############################
# Main section of the script #
##############################

## Script loops through years and processes reports for each year
for YEAR in ${YEARS[@]}; do
        echo "Getting files for ${YEAR}."
        TRANS_ITEM=""
        ## Script loops through reports (above) and concatenates TDAccess command
        
        for REPORT in ${REPORTS[@]}; do
                TS="$(date +"%Y%m%d_%H%M%S")"
                ## Script checks to see the report suffix should be xml or txt
                
                if [ ${REPORT} = "COMO" ] || [ ${REPORT} = "CRPN" ] || [ ${REPORT} = "CRMY" ]; then
                	SUFFIX="xml"
			REPORT_TYPE=""
                else
                	SUFFIX="txt"
			REPORT_TYPE="ISR_"
                fi

                ## Script creates a list of file names to copy to backup later
                ## Does this because the timestamp may change between now and the backup
                FILE_LIST+=("${REPORT_TYPE}${REPORT}${YEAR}_${TS}.${SUFFIX}" )
                echo "Adding ${REPORT} files for ${YEAR} to request."

                ## Script does the actual assembly and concatenation of the text here
                TRANS_ITEM+="transfer=(name=CCA${REPORT} receive=${INCOMING_HOME}/${REPORT_TYPE}${REPORT}${YEAR}_${TS}.${SUFFIX} receiveclass='${REPORT}${YEAR}' ) "
        done

        ## Script does the final assembly of the command here, adding the tdclient and preamble
        ACMD="${TDCLIENT} network=saigportal RESET \"${TRANS_ITEM}\""
        echo "Making TDAccess request for ${YEAR} reports."

        ## Echo the command that will/would be executed
        ## echo ${ACMD}

        # Script executes the tdaccess command with the preamble and arguments assembled above
        ${ACMD}

        ## Wait between execution of the commands for each year
        ## If the second execution starts before the first one finishes
        ## it will throw errors about missing .ini files etc
        echo "Waiting for the ${YEAR} TDClient command to finish..."
        sleep 10
done

#######################################
# copy the files to the backup folder #
#######################################

## Script takes the array of file names we created above
## loops through them and either backs them up or tells us it's not needed
for FILE_NAME in ${FILE_LIST[@]}; do
        if [ -f "${INCOMING_HOME}/${FILE_NAME}" ]; then
                echo "copying ${FILE_NAME} to ${INCOMING_BAK}/${FILE_NAME}"
                cp ${INCOMING_HOME}/${FILE_NAME} ${INCOMING_BAK}/${FILE_NAME}
                echo "removing headers and footers from ${FILE_NAME}"
                sed -i '/^O\*N05/ d' ${INCOMING_HOME}/${FILE_NAME}
                sed -i '/^O\*N95/ d' ${INCOMING_HOME}/${FILE_NAME}
        else
                echo "Nothing to back up."
        fi
done