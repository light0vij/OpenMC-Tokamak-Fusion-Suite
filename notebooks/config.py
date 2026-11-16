# config.py

#Data Libraries

import os

endf8b = '/nuclear_data/endfb-viii.0-hdf5/cross_sections.xml'
endf7b = '/nuclear_data/endfb-vii.1-hdf5/cross_sections.xml'
fendl = '/nuclear_data/fendl-3.2-hdf5/cross_sections.xml'


data_library = fendl

if data_library == endf8b:
    prefix = "endf8b"
elif data_library == endf7b:
    prefix = "endf7b"
elif data_library == fendl:
    prefix = 'fendl'

MODEL_NAME = f"Spherical_tokamak_{prefix}"
BASE_DIR = f"./{MODEL_NAME}_Basic_Configuration"
os.makedirs(BASE_DIR, exist_ok=True)
