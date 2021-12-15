import json

from sm.engine.annotation_lithops.annotation_job import LocalAnnotationJob


dataset = 'dataset_01'
databases = ['pamdb']

imzml_file = f'{dataset}/{dataset}.imzML'
ibd_file = f'{dataset}/{dataset}.ibd'
db_files = [f'databases/{db}.tsv' for db in databases]


with open(f'{dataset}/ds_config.json', 'r') as json_file:
    ds_config = json.load(json_file)


job = LocalAnnotationJob(imzml_file, ibd_file, db_files, ds_config)

pipe = job.pipe
pipe.use_db_cache = False
_ = pipe(use_cache=False)
pipe.clean()