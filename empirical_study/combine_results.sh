#!/bin/bash
######################################################################
#
# This script is part of the Cluster Power Failure project
#
# Details: Combines results across multiple resampling + inference jobs
# Usage: combine_results.sh cfg.sh
#
######################################################################

[[ ! -z $1 && -f $1 ]] && setupfile=$1 || { echo "Error: Config file needed." ; exit 1; }
source $setupfile

# Sum detected clusters (see also $outputDirRecord)
mkdir -p $combinedSummaryDir
combinedSummaryImgPrefix="$combinedSummaryDir/all_clusters"

for sign in Pos Neg; do
    
    filename="all_clusters_${sign}.nii.gz"
    filelist=$(find $outputDir -maxdepth 3 -name "$filename")
    combinedSummaryImg="$combinedSummaryDir/all_clusters_${sign}_sum.nii.gz"
 
    if [[ -f "$combinedSummaryImg" ]]; then
        read -r -p "Summary image ${combinedSummaryImg} exists. Overwrite? Press [Y/y] to overwrite, any other character to exit." response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            combSumImg_old="$combinedSummaryDir/all_clusters_${sign}_sum__old"$(date '+%H%M%S')".nii.gz"
            mv ${combinedSummaryImg} ${combSumImg_old} 
            printf "Overwriting summary image but saved old under ${combSumImg_old}.\n"
        else
            printf "Okay, exiting.\n"
            exit
        fi
    fi

    3dMean -sum -prefix $combinedSummaryImg $filelist
    printf "Finished ${sign} - see combined results here: $combinedSummaryImg . \n"

done

printf "Exiting. \n"


