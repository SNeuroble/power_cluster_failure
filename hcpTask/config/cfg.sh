# Paths and parameters for HCP Cluster Power Failure

### PARAMETERS (SPECIFY)

testing=false

# Number of tests
nPermutations=500

# Data
task="WM"
hcpReleaseNo="1200"
nSubs_subset=20 #20 for final sim

# Software + thresholds 
Software="FSL" # TODO: right now FSL is the only choice
doRandomise=true
doTFCE=true
CDT="3.1" #z-val
CDTp="0.001" #p-val
FWEthreshold="0.95"
nPerms_forRandomise=1000 #5000 is recommended to resolve within p+/-0.01 

# Parallelization parameters 
njobs=8 # divy permutations across njobs
first_job_to_launch=1 # for doing a subset of jobs
last_job_to_launch=8 # for doing a subset of jobs

# Base directories
scriptsDir="/home/ec2-user/scripts/hcpTask"
dataDir="/home/ec2-user/data/hcpTask"


### DIRECTORIES AND OTHER SETUP

# Task/cope pairs: SOCIAL_cope6; WM_cope20; GAMBLING_cope6; RELATIONAL_cope4; EMOTION_cope3
case $task in
    'SOCIAL')
        copeNum="6" ;;
    'WM')
        copeNum="20" ;;
    'GAMBLING')
        copeNum="6" ;;
    'RELATIONAL')
        copeNum="4" ;;
    'EMOTION')
        copeNum="3" ;;
    *)
    echo "Error: must specify task."
    exit
esac


# More setup
maskThresh=$CDT
one_minus_CDTp=$(echo "1 - $CDTp" | bc)
nperms_per_job=$(echo "$nPermutations / ($njobs-1)" | bc) # divy up perms for jobs; output floored
njobs_in_subset=$(( $last_job_to_launch - $first_job_to_launch + 1 ))

# Directories and key files
dataMasterDir="${dataDir}/${task}_cope${copeNum}"
subNamesWithInput="$dataMasterDir/hcp_file_names_S${hcpReleaseNo}_with_cope${copeNum}.txt"
nSubs_total=$(wc -l < $subNamesWithInput)

# Full dataset repository
dataDir_localRepository="$dataMasterDir/GroupSize$nSubs_total"
dataDir_localRepository_lowerLevel="$dataDir_localRepository/lower_level"

# Processing files, settings, &c
if [ "$doTFCE" = true ]; then
    RandomiseOptions_WithThresholds="-T -1"
    RandomiseOptions_NoThresholds="${RandomiseOptions_WithThresholds} -R"
    UncorrectedTstat="tfce_tstat1"
    ClusterTstat="tfce_corrp_tstat1"
else
    RandomiseOptions_WithThresholds="-c ${maskThresh} -1"
    RandomiseOptions_NoThresholds="${RandomiseOptions_WithThresholds} -x"
    UncorrectedTstat="tstat1"
    ClusterTstat="clustere_corrp_tstat1"
fi
processedSuffix="processed"
designTemplate="$scriptsDir/design_templates/design_template.fsf" #FLAME

# Ground truth data folders and mask
temp="-temp" # TODO: remove when stuff migrated back to orig bucket
cloudDataDir="s3://hcp-openaccess$temp/HCP_${hcpReleaseNo}"
cloudDataDir_contd="MNINonLinear/Results/tfMRI_$task/tfMRI_${task}_hp200_s4_level2vol.feat"
hcpConfigFile="$scriptsDir/config_files/hcp_access_S$hcpReleaseNo"
inputFileSuffix="cope${copeNum}.feat"
subNames="$scriptsDir/hcp_file_names_S${hcpReleaseNo}.txt"
groundTruthFolder="$dataDir_localRepository"
maskDir="${groundTruthFolder}/mask"
groundTruthTstat="${groundTruthFolder}/${processedSuffix}_tstat1.nii.gz"
groundTruthMask="${groundTruthFolder}/${processedSuffix}_clustere_corrp_tstat1.nii.gz" # TODO: come back
groundTruthDcoeff="${groundTruthFolder}/dcoeff.nii.gz"

# Output directories
outputDirSuffix=$( [ $doRandomise = "true" ] && echo "randomise" || echo "FLAME" )
outputDirSuffix=$( [ $doTFCE = "true" ] && echo "${outputDirSuffix}TFCE" || echo "$outputDirSuffix" )
outputDirSuffix=$( [ $testing = "true" ] && echo "${outputDirSuffix}TESTING" || echo "$outputDirSuffix" )
outputDir="$dataMasterDir/GroupSize${nSubs_subset}__${outputDirSuffix}"
subjectRandomizations="$outputDir/subIDs"
outputDirRecord="$outputDir/existing_dirs.txt"
resultImgSuffix=".gfeat/cope1.feat/cluster_mask_zstat1.nii.gz"
combinedSummaryDir="$outputDir/Summary"