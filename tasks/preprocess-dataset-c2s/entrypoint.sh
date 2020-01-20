#!/bin/bash

###########################################################
MAX_DATA_CONTEXTS=1000
MAX_CONTEXTS=200
SUBTOKEN_VOCAB_SIZE=27567
TARGET_VOCAB_SIZE=6328
NUM_THREADS=64
PYTHON=python3
###########################################################

mkdir -p /mnt/outputs

TRAIN_DATA_FILE=/mnt/outputs/train.raw.txt
VAL_DATA_FILE=/mnt/outputs/valid.raw.txt
TEST_DATA_FILE=/mnt/outputs/test.raw.txt
BASELINE_DATA_FILE=/mnt/outputs/baseline.raw.txt
EXTRACTOR_JAR=/code2seq/JavaExtractor/JPredict/target/JavaExtractor-0.0.1-SNAPSHOT.jar

echo "Extracting paths from validation set..."
${PYTHON} /code2seq/JavaExtractor/extract.py --dir /mnt/inputs/valid.jsonl.gz --max_path_length 8 --max_path_width 2 --num_threads ${NUM_THREADS} --jar ${EXTRACTOR_JAR} > ${VAL_DATA_FILE}
echo "Finished extracting paths from validation set"
echo "Extracting paths from test set..."
${PYTHON} /code2seq/JavaExtractor/extract.py --dir /mnt/inputs/test.jsonl.gz --max_path_length 8 --max_path_width 2 --num_threads ${NUM_THREADS} --jar ${EXTRACTOR_JAR} > ${TEST_DATA_FILE}
echo "Finished extracting paths from test set"
echo "Extracting paths from training set..."
${PYTHON} /code2seq/JavaExtractor/extract.py --dir /mnt/inputs/train.jsonl.gz --max_path_length 8 --max_path_width 2 --num_threads ${NUM_THREADS} --jar ${EXTRACTOR_JAR} | shuf > ${TRAIN_DATA_FILE}
echo "Finished extracting paths from training set"

EXTRA_FLAG=""
if [ -f /mnt/inputs/baseline.jsonl.gz ]; then
  echo "Extracting paths from baseline set..."
  ${PYTHON} /code2seq/JavaExtractor/extract.py --dir /mnt/inputs/baseline.jsonl.gz --max_path_length 8 --max_path_width 2 --num_threads ${NUM_THREADS} --jar ${EXTRACTOR_JAR} > ${BASELINE_DATA_FILE}
  echo "Finished extracting paths from baseline set"
  EXTRA_FLAG="--baseline_data ${BASELINE_DATA_FILE}"
fi

TARGET_HISTOGRAM_FILE=/mnt/outputs/histo.tgt.c2s
SOURCE_SUBTOKEN_HISTOGRAM=/mnt/outputs/histo.ori.c2s
NODE_HISTOGRAM_FILE=/mnt/outputs/histo.node.c2s

echo "Creating histograms from the training data"
cat ${TRAIN_DATA_FILE} | cut -d' ' -f1 | tr '|' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${TARGET_HISTOGRAM_FILE}
cat ${TRAIN_DATA_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f1,3 | tr ',|' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${SOURCE_SUBTOKEN_HISTOGRAM}
cat ${TRAIN_DATA_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f2 | tr '|' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${NODE_HISTOGRAM_FILE}

${PYTHON} /code2seq/preprocess.py --train_data ${TRAIN_DATA_FILE} ${EXTRA_FLAG} --test_data ${TEST_DATA_FILE} --val_data ${VAL_DATA_FILE} \
  --max_contexts ${MAX_CONTEXTS} --max_data_contexts ${MAX_DATA_CONTEXTS} --subtoken_vocab_size ${SUBTOKEN_VOCAB_SIZE} \
  --target_vocab_size ${TARGET_VOCAB_SIZE} --subtoken_histogram ${SOURCE_SUBTOKEN_HISTOGRAM} \
  --node_histogram ${NODE_HISTOGRAM_FILE} --target_histogram ${TARGET_HISTOGRAM_FILE} --output_name /mnt/outputs/data

# If all went well, the raw data files can be deleted, because preprocess.py creates new files 
# with truncated and padded number of paths for each example.
rm -f ${TRAIN_DATA_FILE} ${VAL_DATA_FILE} ${TEST_DATA_FILE} ${BASELINE_DATA_FILE}
