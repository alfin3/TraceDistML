import os
import time
import sys
import traceback
import numpy as np
import tensorflow as tf
from tf_data import DATA
from tf_multilayer_char_lstm import CHAR_LSTM
import opentracing
import lightstep

#language
EN_LOWERCASE = 'abcdefghijklmnopqrstuvwxyz'
EN_UPPERCASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
DE_LOWERCASE = 'abcdefghijklmnopqrstuvwxyzüäöß'
DE_UPPERCASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZÜÄÖ'
RU_LOWERCASE = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'
RU_UPPERCASE = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'
LANGUAGE_CHARS = EN_LOWERCASE + EN_UPPERCASE
VOCAB_SIZE = len(LANGUAGE_CHARS) + 1

#data
EN_DATA_FILE = 'news.2015.en.shuffled'
DE_DATA_FILE = 'news.2015.de.shuffled'
RU_DATA_FILE = 'news.2015.ru.shuffled'
DATA_ROOT = './'
DATA_FILE = os.path.join(DATA_ROOT, EN_DATA_FILE)
VALID_SET_SIZE = 10000

#model
BATCH_SIZE = 256
NUM_UNROLLINGS = 10
START_LEARNING_RATE = 2.0 
DECAY_STEPS = 5000
DECAY_RATE = 0.75 
CLIP_NORM = 2.5 
TRAIN_KEEP_PROB = 0.85
EVAL_KEEP_PROB = 1.0
LSTM_TOPOLOGY = [VOCAB_SIZE, 64, 64]
CLASSIFIER_TOPOLOGY = [64, 
                       2048, 2048, 2048, 2048, 2048, 2048,
                       VOCAB_SIZE] 
NUM_STEPS = 10001
PRINT_FREQ = 100
FREQ_MULTIPLE = 10  # PRINT_FREQ mutiple for validation
PRINT_SENTENCE_SIZE = 100
PRINT_NUM_SENTENCES = 10

#records
MODEL_NAME = '2x64_6x2048_A'
RECORDS_ROOT = './'
CHECKPOINT_FOLDER = os.path.join(RECORDS_ROOT, 'checkpoints', MODEL_NAME, '')
GRAPH_FOLDER = os.path.join(RECORDS_ROOT, 'graphs', MODEL_NAME, '')

#tracing
COMPONENT_NAME = MODEL_NAME
ACCESS_TOKEN = 'YOURTOKEN'
COLLECTOR_HOST = 'collector.lightstep.com'
COLLECTOR_PORT = 443
COLLECTOR_ENCRYPTION = 'tls'
NUM_BUILDS = 100
    
def read_text_file(text_file):
    """Read a text file."""
    try:
        with open(text_file, "rb") as f:
            text = tf.compat.as_str(f.read())    
    except Exception as e:
        print("Unable to open", text_file, ":", e)
        raise
    return text

def initialize():
    """The main building function."""
    with tf.Session() as session: 
        with opentracing.tracer.start_active_span('init') as parent_scope:
            session.run(tf.global_variables_initializer())        
        print("Variables initialized")

def lightstep_tracer():
    """Set up a LightStep tracer."""
    return lightstep.Tracer(component_name=COMPONENT_NAME,
                            access_token=ACCESS_TOKEN,
                            collector_host=COLLECTOR_HOST,
                            collector_port=COLLECTOR_PORT,
                            collector_encryption=COLLECTOR_ENCRYPTION)

def main():
    """Run graph builds without training and validation."""
    with lightstep_tracer() as tracer:
        opentracing.tracer = tracer                
        for build_ix in range(NUM_BUILDS):
            graph = tf.Graph()
            with graph.as_default():
                model = CHAR_LSTM(batch_size=BATCH_SIZE, 
                                  vocab_size=VOCAB_SIZE, 
                                  num_unrollings=NUM_UNROLLINGS,
                                  lstm_topology=LSTM_TOPOLOGY,
                                  classifier_topology=CLASSIFIER_TOPOLOGY,
                                  start_learning_rate=START_LEARNING_RATE, 
                                  decay_steps=DECAY_STEPS,
                                  decay_rate=DECAY_RATE,
                                  clip_norm=CLIP_NORM,
                                  optr_tracer=opentracing.tracer)
                model.build_graph()
                initialize()
                print("Build count: %d" % (build_ix + 1))

if __name__ == '__main__':
    main()
