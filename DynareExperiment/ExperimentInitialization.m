%[text] # Experiment Initialization Function
%[text] Use this function to initialize the experiment, including tasks like loading data, before trials are run. Experiment Manager executes this initialization function before it begins the trials. When the trial is running, use `params.InitializationFunctionOutput` to access the initialization function output.
%[text] ## Input
%[text] - This function does not accept any input arguments. \
%[text] ## Output
%[text] - `output` $-$ Experiment data returned as a structure. \
%[text] ## Initialization Function
function output = ExperimentInitialization()
% Edit the line above when running into a place where dynare is not
% installed by default. 
output.dynareLocation = which('dynare.m');

% Add any other initialization task
% output.data = 
end

%[appendix]{"version":"1.0"}
%---
