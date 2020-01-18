#!/bin/sh
set -x
# python sample.py --train_path data/en-fr/europarl-v7.fr-en.val.tsv --dev_path data/en-fr/europarl-v7.fr-en.val.tsv
python train.py --train_path data/java-small/transforms.Identity/train.tsv --dev_path data/java-small/transforms.Identity/valid.tsv --expt_name java_small_identity_lstm
# python train.py --train_path data/java-small/transforms.Identity/train.tsv --dev_path data/java-small/transforms.Identity/valid.tsv --expt_name java_small_identity  --resume --expt_dir experiment/java_small_identity --load_checkpoint Best_F1
