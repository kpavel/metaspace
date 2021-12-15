# Example


## clone repository
```
git clone -b ce git@github.com:kpavel/metaspace.git
cd metaspace/example
```

## download datasets.
in your browser open following (url)[https://metaspace2020.eu/datasets?ds=2016-09-22_11h16m11s], press Download and save Brain02_Bregma1-42_02.imzML and Brain02_Bregma1-42_02.ibd
move those files to dataset_01 folder naming them dataset_01.imzML and dataset_01.ibd
```
mv Brain02_Bregma1-42_02.imzML dataset_01/dataset_01.imzML
mv Brain02_Bregma1-42_02.ibd dataset_01/dataset_01.ibd

# after that, your dataset_01 folder should contain:
dataset_01/
├── dataset_01.ibd
├── dataset_01.imzML
└── ds_config.json
```

## create virtual environment based on python3.8
```
virtualenv -p python3.8 venv3.8
source ./venv3.8/bin/activate
```

## install dependencies
```
pip install wheel Jinja2
pip install -r ../metaspace/engine/requirements.txt
pip install -e ../metaspace/engine/
```

## Configuration
Edit [conf/config.json](conf/config.json) configuration file. all the entries with \<> are mandatory and must be updated. Follow [Lithops](https://github.com/lithops-cloud/lithops/blob/master/config/README.md#compute-and-storage-backends) if you need to configure other storage backends, like CEPH
```
{
    "lithops": {
        "lithops": {
            "storage_bucket": "<EXISTING_COS_BUCKET>",
            "storage": "ibm_cos",
            "mode": "serverless",
            "include_modules": ["engine/sm"],
            "data_cleaner": true,
            "data_limit": false,
            "workers": 100,
            "execution_timeout": 2400
        },
        "serverless": {
            "backend": "code_engine",
            "runtime_timeout": 1200,
            "runtime_memory": 2048
        },
        "localhost": {},
        "ibm": {"iam_api_key": "<IAM_API_KEY>"},
        "code_engine": {
            "namespace": "<NAMESPACE>",
            "region": "<REGION>",
            "runtime": "kpavel/meta-ce-lithops-runtime:latest",
            "runtime_memory": 1024, # can be changed according to possible pairs
            "runtime_cpu": 0.25
        },
        "ibm_cos": {
            "region": "us-east" # can be changed to different one
        },
        "sm_storage": {
            "imzml": ["<Existing COS Bucket>", "imzml"],
            "moldb": ["<Existing COS Bucket>", "moldb"],
            "centroids": ["<Existing COS Bucket>", "centroids"],
            "pipeline_cache": ["<Existing COS Bucket>", "pipeline_cache"]
        }
    }
}
```

## Run the example
```
python script.py
```

## In case building custom lithops code-engine runtime image, please follow lithops readme to create [config.yaml](https://github.com/lithops-cloud/lithops/blob/master/docs/source/compute_config/code_engine.md) or use [lithopscloud](https://pypi.org/project/lithopscloud/) config tool. Then run
```
cd ../metaspace/engine
lithops runtime build -f ./docker/code_engine/Dockerfile -c config.yaml -b code_engine <DOCKERHUB_USER/RUNTIME_DOCKER_IMAGE>
```
