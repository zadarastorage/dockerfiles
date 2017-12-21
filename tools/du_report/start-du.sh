#!/bin/sh

run_start=$(date -u +'%Y-%m-%d_%H-%M-%S')
echo "RUN START /t ${run_start}" >> "/var/log/run.log"

if [ ! -d ${OUTPUT_DIRECTORY} ]
then
	mkdir -p ${OUTPUT_DIRECTORY}
fi

if [ -n ${SIZES_HUMAN_READABLE} ] && [ ${SIZES_HUMAN_READABLE} == "true" ]
then
	human_readable_arg="-h"
else
	human_readable_arg=""
fi
if [ -n "${TREE}" ] && [ "${TREE}" == "true" ]
then
	if [ -n "${TREE_OUTPUT_FORMAT}" ] && [ ${TREE_OUTPUT_FORMAT} == "JSON" ] 
	then
		tree_output_arg="-J"
		file_ext=".json"
	elif [ -n "${TREE_OUTPUT_FORMAT}" ] && [ ${TREE_OUTPUT_FORMAT} == "XML" ] 
	then
		tree_output_arg="-X"
		file_ext=".xml"
	else
		tree_output_arg=""
		file_ext=".txt"
	fi	
	tree ${TARGET_DIRECTORY} --du -T ${DIRECTORY_DEPTH} -d ${human_readable_arg} ${tree_output_arg} > "${OUTPUT_DIRECTORY}/UsageReport_Tree_${run_start}${file_ext}"
else
	file_ext=".txt"
	du ${TARGET_DIRECTORY} -d ${DIRECTORY_DEPTH} -c ${human_readable_arg} > "${OUTPUT_DIRECTORY}/UsageReport_DU_${run_start}${file_ext}"	
fi
run_end=$(date -u +'%Y-%m-%d_%H-%M-%S')
echo "RUN COMPLETE /t ${run_end}"  >> "/var/log/run.log"
