#!/bin/bash
#SBATCH --nodes=4           # total nodes
#SBATCH --gres=gpu:2        # how many GPUs per node
#SBATCH --cpus-per-task=2   # Cores proportional to GPUs: 6 on Cedar, 16 on Graham.
#SBATCH --mem=64gb          # Memory proportional to GPUs: 32000 Cedar, 64000 Graham.
#SBATCH --time=4-02:10      # days-hours:minutes
#SBATCH --output=job-%j-%N.out
set -x

#####################
#  Configuration
#####################
TRAINER=${1-pretrain}
SETUP=${2}
DEVICES=${3-0} # only needed for local training (non-Slurm)

# redirect the following to console logs (BEGIN)
{

DATE=$(date)
CODE_VER=$(test -e pya0 && cd pya0 && pwd && git rev-parse HEAD)
COMMAND="$0 $@"

EPOCHS=10
TEST_CYCLE=100
case $TRAINER-${SETUP} in
   pretrain-from-scratch)
    DEV_BSIZE=30
    SAVE_FOLD=1

    DATA_VER=arjmPWtGwzKrkmR
    START_POINT=bert-from-scratch
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards-for-scratch.txt
    TEST_FILE=test.txt
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-vocab.pkl"
    #TRAINER_ARGS="--lr 1e-4"
    ;;

   pretrain-for-newvocab)
    DEV_BSIZE=30
    SAVE_FOLD=2

    DATA_VER=arjmPWtGwzKrkmR
    START_POINT=bert-base-uncased
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards-for-newvocab.txt
    TEST_FILE=test.txt
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-vocab.pkl"
    TRAINER_ARGS=
    ;;

   pretrain-for-newvocab-using-v3-data-a100)
    DEV_BSIZE=30
    SAVE_FOLD=1

    DATA_VER=nzzsWr7Nsz6sjfW
    START_POINT=bert-base-uncased
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=100
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-vocab-v3.pkl"
    TRAINER_ARGS="--architecture standard --warmup-epochs 1 --lr 1e-4"
    ;;

   pretrain-condenser-using-v3-allenv-a100)
    DEV_BSIZE=12
    SAVE_FOLD=1

    DATA_VER=FDoixTjWwJPo5TD
    START_POINT=bert-base-uncased
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=100
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-vocab-v3-allenv.pkl"
    TRAINER_ARGS="--architecture condenser --warmup-epochs 1 --lr 1e-4"
    ;;

   pretrain-cotmae-using-v3-allenv-a100)
    DEV_BSIZE=12
    SAVE_FOLD=1

    DATA_VER=FDoixTjWwJPo5TD
    START_POINT=bert-base-uncased
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=100
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-vocab-v3-allenv.pkl"
    TRAINER_ARGS="--architecture mae --warmup-epochs 1 --lr 1e-4"
    ;;

   pretrain-for-standard-using-v3-allenv-a6000)
    DEV_BSIZE=38
    SAVE_FOLD=1

    DATA_VER=bertnsp
    START_POINT=bert-base-uncased
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=100
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-vocab-v3-allenv.pkl"
    TRAINER_ARGS="--architecture standard --warmup-epochs 1 --lr 1e-4"
    ;;

   pretrain-condenser-using-v3-allenv-a6000)
    DEV_BSIZE=16
    SAVE_FOLD=1

    DATA_VER=FDoixTjWwJPo5TD
    START_POINT=bert-base-uncased
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=100
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-vocab-v3-allenv.pkl"
    TRAINER_ARGS="--architecture condenser --warmup-epochs 1 --lr 1e-4"
    ;;

   pretrain-cotmae-using-v3-allenv-a6000)
    DEV_BSIZE=16
    SAVE_FOLD=1

    DATA_VER=FDoixTjWwJPo5TD
    START_POINT=bert-base-uncased
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=100
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-vocab-v3-allenv.pkl"
    TRAINER_ARGS="--architecture mae --warmup-epochs 1 --lr 1e-4"
    ;;

   pretrain-for-newvocab-using-v2-data-a100)
    DEV_BSIZE=30
    SAVE_FOLD=1

    DATA_VER=Ce6aTdC3AsGEXj9
    START_POINT=bert-base-uncased
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=100
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-vocab-v2.pkl"
    TRAINER_ARGS=
    ;;

   finetune-from-base)
    DEV_BSIZE=8
    SAVE_FOLD=2

    DATA_VER=GceiSWS4TSYsySa
    START_POINT=bert-base-uncased
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=200
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-data.pkl.tags.ids"
    TRAINER_ARGS="--lr 5e-7"
    ;;

   finetune-from-pretrained)
    DEV_BSIZE=8
    SAVE_FOLD=2

    DATA_VER=GceiSWS4TSYsySa
    START_POINT=bert-pretrained-for-math-7ep/6_3_1382/
    TOK_CKPOINT=bert-tokenizer-for-math
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=200
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-data.pkl.tags.ids"
    TRAINER_ARGS="--lr 5e-7"
    ;;

   tag_prediction-direct)
    DEV_BSIZE=8
    SAVE_FOLD=2

    DATA_VER=aMGYy47dPPXbQm6
    START_POINT=bert-pretrained-for-math-7ep-3.5b/7-5-921
    TOK_CKPOINT=bert-tokenizer-for-math
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=200
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-data.pkl.tags.ids direct"
    TRAINER_ARGS="--lr 2e-6 --dev_map 2"
    #TRAINER_ARGS="--lr 2e-6 --dev_map 2 --debug"
    ;;

   tag_prediction-variational)
    DEV_BSIZE=25
    SAVE_FOLD=2

    DATA_VER=aMGYy47dPPXbQm6
    START_POINT=bert-pretrained-for-math-7ep-3.5b/7-5-921
    TOK_CKPOINT=bert-tokenizer-for-math
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=200
    CALL_ARGS="data.$DATA_VER/mse-aops-2021-data.pkl.tags.ids variational"
    #TRAINER_ARGS="--lr 2e-5 --dev_map 2 --debug"
    TRAINER_ARGS="--lr 2e-5 --dev_map 2"
    ;;

   colbert-on-basilisk-using-bertnsp)
    EPOCHS=8
    DEV_BSIZE=16
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=bertnsp-6-1-0
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS="512" # qmax
    TRAINER_ARGS="--warmup-epochs 1 --lr 2e-5 --active_fp16"
    ;;

   colbert-on-basilisk-using-cotmae)
    EPOCHS=8
    DEV_BSIZE=18
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=cotmae-6-1-0/encoder.ckpt/
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS="512" # qmax
    TRAINER_ARGS="--warmup-epochs 1 --lr 2e-5 --active_fp16"
    ;;

   single_vec_retriever-on-basilisk-using-bertnsp350)
    DEV_BSIZE=18
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=bertnsp-3-5-0
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-basilisk-using-bertnsp)
    DEV_BSIZE=18
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=bertnsp-6-1-0
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-basilisk-using-condenser350)
    DEV_BSIZE=18
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=condenser-3-5-0/encoder.ckpt/
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-basilisk-using-condenser)
    DEV_BSIZE=18
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=condenser-6-1-0/encoder.ckpt/
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-basilisk-using-cotmae350)
    DEV_BSIZE=18
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=cotmae-3-5-0/encoder.ckpt/
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-basilisk-using-cotmae)
    DEV_BSIZE=18
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=cotmae-6-1-0/encoder.ckpt/
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-basilisk-for-splade__1e-4)
    DEV_BSIZE=12
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=cotmae-6-1-0/encoder.ckpt/
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--architecture splade --splade_reg 1e-4 --warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-basilisk-for-splade__1e-4_somemath)
    DEV_BSIZE=12
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=cotmae-6-1-0/encoder.ckpt/
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--architecture splade --splade_reg 1e-4 --splade_mask_mode somemath --warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-basilisk-for-splade__1e-2)
    DEV_BSIZE=12
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=cotmae-6-1-0/encoder.ckpt/
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--architecture splade --splade_reg 1e-2 --warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-basilisk-for-splade__1e-2_somemath)
    DEV_BSIZE=12
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=cotmae-6-1-0/encoder.ckpt/
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--architecture splade --splade_reg 1e-2 --splade_mask_mode somemath --warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-basilisk-for-splade__1e6_somemath)
    DEV_BSIZE=12
    SAVE_FOLD=1

    DATA_VER=djmsGSbXAwWConj
    START_POINT=cotmae-6-1-0/encoder.ckpt/
    TOK_CKPOINT=math-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS="--architecture splade --splade_reg 1e-6 --splade_mask_mode somemath --warmup-epochs 1 --lr 2e-5"
    ;;

   single_vec_retriever-on-narval-using-pretrained-model)
    DEV_BSIZE=16
    SAVE_FOLD=2

    DATA_VER=kYsYFf5JbdbZFda
    START_POINT=bert-pretrained-for-math-7ep-3.5b/7-5-921
    TOK_CKPOINT=bert-tokenizer-for-math
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=200
    CALL_ARGS=
    TRAINER_ARGS=
    ;;

   single_vec_retriever-on-narval-using-finetuned-model)
    DEV_BSIZE=16
    SAVE_FOLD=2

    DATA_VER=kYsYFf5JbdbZFda
    START_POINT=tag-predictor-8-6-7642
    TOK_CKPOINT=bert-tokenizer-for-math
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=200
    CALL_ARGS=
    TRAINER_ARGS=
    ;;

   single_vec_retriever-from-vanilla-backbone-v3-on-v100)
    EPOCHS=8
    DEV_BSIZE=8
    SAVE_FOLD=1

    DATA_VER=pHoLt8iLSrkD3XB
    START_POINT=bert-base-uncased
    TOK_CKPOINT=bert-tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS='--lr 3e-6'
    ;;

   single_vec_retriever-from-3ep-pretrained-v3-on-narval)
    EPOCHS=8
    DEV_BSIZE=14
    SAVE_FOLD=1

    DATA_VER=pHoLt8iLSrkD3XB
    START_POINT=bert-pretrained-for-math/3-1-0
    TOK_CKPOINT=bert-tokenizer-for-math
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS='--lr 3e-6'
    ;;

   single_vec_retriever-from-7ep-pretrained-v3-on-v100)
    EPOCHS=8
    DEV_BSIZE=8
    SAVE_FOLD=1

    DATA_VER=pHoLt8iLSrkD3XB
    START_POINT=bert-pretrained-for-math/7-5-921
    TOK_CKPOINT=bert-tokenizer-for-math
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS='--lr 3e-6'
    ;;

   single_vec_retriever-from-scibert-v3-on-narval)
    EPOCHS=8
    DEV_BSIZE=14
    SAVE_FOLD=1

    DATA_VER=pHoLt8iLSrkD3XB
    START_POINT=scibert_model
    TOK_CKPOINT=scibert_tokenizer
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS='--lr 3e-6'
    ;;

   single_vec_retriever-from-azbert-v3-on-v100)
    EPOCHS=8
    DEV_BSIZE=8
    SAVE_FOLD=1

    DATA_VER=gqstFZmWHCLGXe3
    START_POINT=bert-pretrained-for-math-7ep/6_3_1382
    TOK_CKPOINT=bert-tokenizer-for-math
    SHARDS_LIST=shards.txt
    TEST_FILE=test.txt
    TEST_CYCLE=300
    CALL_ARGS=
    TRAINER_ARGS='--lr 3e-6'
    ;;

   *)
    echo "[Bad args] $COMMAND"
    exit 1;
    ;;
esac

######################################
#   Extract Slurm Header Arguments
######################################
N_NODE=$(cat $0 | grep -Po '(?<=SBATCH --nodes=)[0-9]+')
N_GPUS=$(cat $0 | grep -Po '(?<=SBATCH --gres=gpu:)[0-9]+')
if [ -z "$N_GPUS" ]; then
    N_GPUS=$(cat $0 | grep -Po '(?<=SBATCH --gres=gpu:).+:[0-9]+')
    N_GPUS=$(echo $N_GPUS | cut -f 2 -d':')
fi

if [ -z "$N_GPUS" -o -z "$N_NODE" ]; then
    echo "No value in: num_node=$N_NODE, num_gpu=$N_GPUS"
    exit 1
else
    echo "num_node=$N_NODE, num_gpu=$N_GPUS"
fi

#####################
#   Download Data
#####################
DATA_DIR=data.$DATA_VER
set -e
if [ ! -e $DATA_DIR ]; then
    tarball=`mktemp`
    wget https://vault.cs.uwaterloo.ca/s/$DATA_VER/download -O $tarball
    tar xzf $tarball --one-top-level=$DATA_DIR --strip-components 1
fi
set +e

#####################
#   Run SLURM Job
#####################
export NCCL_BLOCKING_WAIT=1  # Set this variable to use the NCCL backend
export NCCL_IB_DISABLE=1
export NCCL_DEBUG=INFO
export NCCL_P2P_DISABLE=1

export SLURM_ACCOUNT=def-jimmylin
export SBATCH_ACCOUNT=$SLURM_ACCOUNT
export SALLOC_ACCOUNT=$SLURM_ACCOUNT

export TORCH_DISTRIBUTED_DEBUG=OFF #DETAIL

lower_port=$(cat /proc/sys/net/ipv4/ip_local_port_range | awk '{print $1}')
upper_port=$(cat /proc/sys/net/ipv4/ip_local_port_range | awk '{print $2}')
set +x
for port in $(seq $lower_port $upper_port); do
    nc -z $(hostname) $port 2>/dev/null || break
done
set -x
echo "Using TCP port ${port} ..."

if which srun; then
    let TOTAL_N="$N_NODE * $N_GPUS"
    srun --unbuffered \
        python ./pya0/utils/transformer.py $TRAINER \
        $DATA_DIR/$START_POINT $DATA_DIR/$TOK_CKPOINT $CALL_ARGS \
        --test_file $DATA_DIR/$TEST_FILE --test_cycle $TEST_CYCLE \
        --shards_list $DATA_DIR/$SHARDS_LIST \
        --cluster tcp://$(hostname):${port} \
        --batch_size $(($TOTAL_N * $DEV_BSIZE)) \
        --save_fold $SAVE_FOLD --epochs $EPOCHS $TRAINER_ARGS
else
    TOTAL_N=$(echo $DEVICES | awk -F',' '{print NF}')
    export SLURM_JOB_ID=$TRAINER-${SETUP}
    python ./pya0/utils/transformer.py $TRAINER \
        $DATA_DIR/$START_POINT $DATA_DIR/$TOK_CKPOINT $CALL_ARGS \
        --test_file $DATA_DIR/$TEST_FILE --test_cycle $TEST_CYCLE \
        --shards_list $DATA_DIR/$SHARDS_LIST \
        --cluster tcp://$(hostname):${port} \
        --batch_size $(($TOTAL_N * $DEV_BSIZE)) \
        --save_fold $SAVE_FOLD --epochs $EPOCHS $TRAINER_ARGS \
        --dev_map $DEVICES
fi;

# redirect the following to console logs (END)
} 2>&1 | tee job-$TRAINER-$SETUP.console.log

# Other example usages
#salloc --nodes=1 --gres=gpu:1 --cpus-per-task=2 --time=0-01:10 --mem=32gb
#salloc --nodes=1 --partition=compute_full_node --gpus-per-node=4 --time=0-01:10 # Mist
#srun --jobid 12345 --pty bash
#
# git clone https://github.com/t-k-/cc-orchestration.git
# git clone https://github.com/approach0/pya0.git
# ln -s cc-orchestration/sbatch-template.sh sbatch.sh
# (cd pya0 && git pull) && (cd cc-orchestration && git pull)
#
# ps -up `nvidia-smi -q -x | grep -Po '(?<=<pid>)[0-9]+'`
