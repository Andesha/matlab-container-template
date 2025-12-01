# matlab-container-template
Template pipleine and Dockerfile for a MATLAB project

# Notes

* Clone down your own version of EEGLAB and install whatever plugins and things you need
* Create main pipeline processing function
  * In this case `eeglab_psd_pipeline.m` does all loading, processing, and saving
  * This function should be tested within MATLAB and work smoothly
  * To test do:
    1. `addpath eeglab;`
    2. `eeglab_psd_pipeline('eeglab/sample_data/eeglab_data.set', 'test.csv', 100, 200)`
    3. This should make a `test.csv` file
    4. Compare against `working_test.csv` as ground truth

