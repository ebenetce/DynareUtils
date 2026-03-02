%[text] # Dynare Experiment
%[text] ## Input
%[text] - `params` $-$ A structure with fields from the Experiment Manager parameter table. In the experiment function, access the parameter values by using dot notation. \
%[text] ## Output
%[text] - The experiment function can return multiple outputs. The names of the output variables appear as column headers in the top of the results table. Each output value must be a numeric, logical, or string scalar and appears in the trial row of the results table. \
%[text] ## Experiment Function
function [oo_, dyver] = DynareExperiment(params)

dynareLocation =  params.InitializationFunctionOutput.dynareLocation;

% Prepare Dynare inputs
dynParams = compose("-D%s=%0.2f", ["BETA"; "ALPHA"; "DELTA"; "RHO"; "SIGMA"; "PHI"], [params.BETA; params.ALPHA; params.DELTA; params.RHO; params.SIGMA; params.PHI])';

% Submit dynare call
out = runDynareModel(which("mymodel.mod"), Flags = ["nolog", "nowarn", dynParams], GetResultsFolder = false, DynareLocation = dynareLocation);

% Collect outputs, the outputs of this function will be the same outputs
% you see on experiment manager, 
oo_ = out.oo_;

% tb_y = oo_.mean(1);
% c_y = oo_.mean(2);
% i_y = oo_.mean(3);

dyver = feval('dynare_version'); %#ok<FVAL>

end

%[appendix]{"version":"1.0"}
%---
