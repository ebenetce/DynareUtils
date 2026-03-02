%[text] # Dynare Utils
%[text] A toolbox with various utilities to assist with the use of Dynare
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] ## Dynare version management
%[text] The toolbox allows setting up Dynare for you, for example, if you run:
setDynare('6.5')
%[text] It will download Dynare and install it as a toolbox in MATLAB. You can also use some additional utilities in case you need to swap versions:
%[text] - **`disableDynare`****\*\*\*\*()**: Disables the current version of Dynare without removing it from the system
%[text] - **`uninstallDynare(<version>)`**: Completely removes the version of Dynare from your computer \
%[text] Please note that if you install Dynare separately the toolbox attempts to help, but the results can be wrong
%%
%[text] ## Running Dynare in Parallel
%[text] To make it easier, try first running the model like this (you need to [start a parallel environment ](internal:H_1c5d)first)
%[text] ```matlabCodeExample
%[text] dynareParallel('yourModFile.mod')
%[text] ```
%[text] %[text:anchor:H_5962] This function accepts some additional options:
%[text] ```matlabCodeExample
%[text] out = dynareParallel('yourModFile.mod', ...                               % Main mod file, can be in any folder
%[text]                      Flags = ["nowarn", "nolog"]), ...                    % standard options of the dynare cmmand
%[text]                      AdditionalFiles = ["steadystate.m", "data.mat"], ... % additional files needed for your model
%[text]                      UseParallel = true, ...                              % whether to use parallel or not. 
%[text]                      GetResultsFolder = false);                           % Whether to collect the folder with markov chain results and other model outputs 
%[text] 
%[text] % The out variable is a struct with the workspace after running dynare.
%[text] ```
%[text] ### Examples
%[text] #### Markov Chains in parallel
%[text] This applies if you are estimating multiple Markov Chains in parallel. This would be a sample estimation:
%[text] ```matlabCodeExample
%[text] estimation(order=1, datafile=fs2000_data, loglinear,logdata, mode_compute=4, mh_replic=20000, nodiagnostic,
%[text] mh_nblocks=2, mh_jscale=0.8, mode_check);
%[text] ```
%[text] In this case 2 chains are estimated, so you probably want to create a parpool of this type:
%[text] ```matlabCodeExample
%[text] c = parcluster('Processes');
%[text] c.NumThreads = <NumberOfCores>/<NumberOfChains>;
%[text] parpool(c, <NumberOfChains>)
%[text] out = dynareParallel('yourModel.mod')
%[text] ```
%[text] #### Estimation using Parallel computing 
%[text] %[text:anchor:TMP_46da] This applies if you have an estimation block in your model file with the following block:
%[text] ```
%[text] estimation(optim=('UseParallel', true), datafile=usmodel_data,
%[text] mode_compute=1,first_obs=1, presample=4,lik_init=2,prefilter=0,
%[text] mh_replic=0,mh_nblocks=2,mh_jscale=0.20,mh_drop=0.2, nograph, nodiagnostic, tex);
%[text] ```
%[text] **`mode_compute = 1`** establishes that you are using "**`fmincon`**". This is a built-in algorithm and it accepts a parallel flag to speed up the process. To enable this, you need to run it as follows:
%[text] ```matlabCodeExample
%[text] parpool('Processes')
%[text] out = dynareParallel('model_file.mod')
%[text] ```
%%
%[text] ## Running Dynare jobs
%[text] There are multiple ways to submit Dynare jobs and it greatly depends on whether you do it locally or in a cluster. 
%[text] **Note:** If you want to run Dynare in parallel using Jobs, please consider using Dynare 7 or newer
%[text] ### Local machine
%[text] The easiest way to run a dynare job is to use parfeval, this will directly submit the Dynare calculations to a local worker in your machine. However, it is highly encouraged that you submit jobs using the built-in wrapper. Otherwise, simultaneous dynare jobs might override the results. This function has the additional advantage that does not require the MOD file to exist in the same folder where you are launching the job.
%[text] ```matlabCodeExample
%[text] fcn = j = parfeval( @(x) runDynareModel(x, Flags = ["nolog", "nowarn"], CollectResultsFolder = false) )
%[text] j = parfeval(fcn, 2, "C:\Path\To\yourmodel.mod" )
%[text] ```
%[text] Once the job is done, you can then see the Diary
%[text] ```matlabCodeExample
%[text] j.Diary
%[text] ```
%[text] Or collect the outputs:
%[text] ```matlabCodeExample
%[text] out = fetchOutputs(j)
%[text] ```
%[text] If you have selected "**`CollectResultsFolder = true`**" the folder with the results of the run will be copied to current folder, or the results folder specified in the inputs. For more information on this function, please run:
help runDynareModel %[output:68d14b73]
%%
%[text] For a single job, you can probably submit the job with parfeval. However, note that Dynare runs in the same folder where you have the .MOD file, so if more than one job is submitted, the results might be overwritten. In that case In that case, this would be the best:
%[text] ```matlabCodeExample
%[text] c = parcluster('Processes');
%[text] j = submitDynareJob(c, which("agtrend.mod"), "DynareFlags", ["nolog", "nograph"])
%[text] ```
%[text] Then after the job is finished, you can retrieve the diary and the outputs
%[text] ```matlabCodeExample
%[text] j.diary
%[text] out = fetchOutputs(j)
%[text] ```
%[text] You can submit as many as those as you want, they will be run simultaneously in the provided pool of workers
%[text] ### Cluster
%[text] The same function can help in the the submission of a Dynare job into a cluster, you can run this function as:
%[text] ```matlabCodeExample
%[text] c = parcluster('ClusterName');
%[text] j = submitDynareJob(c, which("agtrend.mod"), DynareFlags = ["nolog", "nograph"], ...
%[text]                     DynareLocation = 'C:/Path/To/Dynare', AdditionalFiles = ["file1.mat", "file2.mod"]);
%[text] ```
%[text] This will submit the job to the appropriate cluster. Note than we need to specify the location of Dynare in the cluster as this is probably different than our own (it might not be even the same OS). 
%%
%[text] ## Detailed solution
%[text] ### Issue
%[text] The problem is the use of persistent variables. The code relies on having to initialize certain functions. This is local to the MATLAB session and is not taken into account in the parallel workers.
%[text] If we look at the execution profile below, fmincon calls a function called "**`priordens`**" (marked in red) and a second one "**`dyn_first_order_solver`**" that heavily use persistent variables to be more efficient. 
%[text] ```matlabCodeExample
%[text] function [logged_prior_density, dlprior, d2lprior, info] = priordens(x, pshape, p6, p7, p3, p4, initialization)
%[text] 
%[text] persistent id1 id2 id3 id4 id5 id6 id8
%[text] persistent tt1 tt2 tt3 tt4 tt5 tt6 tt8
%[text] ```
%[text] The problem is that instead of initializing the function the first time is called, Dynare relies in two calls 
%[text] - A first call to refresh the functions
%[text] - A second call to initialize the persistence. \
%[text] This will not be translated to the workers since each has its own copy of the functions and their memory.
%[text] ### Solution
%[text] If the solution above does not work or is lacking functionality. This is the actual solution:
%[text] %[text:anchor:H_6317] **1. Override some Dynare functions**
%[text] Navigate to the folder below and then into the one corresponding to the right Dynare version
dynareUtilsRoot
%[text] Copy the contents of that folder in the same folder where you have the .MOD file. For the case of Dynare 6.x, this should be:
%[text] - global\_initialization.m
%[text] - posterior\_sampler\_core.m
%[text] - set\_dynare\_seed.m
%[text] - set\_prior.m \
%[text] %[text:anchor:H_1c5d] **2. Start a parallel environment**
%[text] For a local run, you can do this:
%[text] ```matlabCodeExample
%[text] parpool('Processes')
%[text] ```
%[text] **Tips**
%[text] - Do not start more Processes than Chains. If you have only 2 chains do this: \
%[text] ```matlabCodeExample
%[text] parpool('Processes', 2)
%[text] ```
%[text] - If you have more cores than chains. You can increase the speed by making sure that NumProcesses x NumThreads = NumCores \
%[text] ```matlabCodeExample
%[text] c = parcluster('Processes')
%[text] c.NumThreads = 2
%[text] parpool(c, 2)
%[text] ```
%[text] %[text:anchor:H_3ee0] **3. Call Dynare**
%[text] After you finished 1 and 2, call Dynare normally.
%[text] ```matlabCodeExample
%[text] dynare fs2000.mod
%[text] ```
%[text] This should run the Markov chains in parallel and the results should match exactly. 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
%---
%[output:68d14b73]
%   data: {"dataType":"text","outputData":{"text":" <strong>runDynareModel<\/strong> Run a Dynare model in an isolated temporary folder.\n \n    [OUT, INFO] = <strong>runDynareModel<\/strong>(NAME) copies the Dynare model file specified\n    by NAME (a string filename or full path) into a running folder, runs\n    Dynare on that model, collects results into OUT, and returns the INFO\n    output from Dynare. By default a timestamped run folder is created in\n    the system temporary directory.\n \n    [...] = <strong>runDynareModel<\/strong>(NAME, Name,Value) specifies additional options\n    using name-value pair arguments. Valid name-value pairs are:\n \n    'Flags'             - (1,:) string, Dynare command-line flags passed\n                          to dynare (default: string.empty()).\n    'AdditionalFiles'   - (1,:) string, paths to additional files to copy\n                          into the run folder (each must exist).\n    'AdditionalFolders' - (1,:) string, paths to additional folders to copy\n                          into the run folder (each must exist).\n    'RunFolder'         - (1,1) string, base folder in which to create the\n                          run folder (default: tempdir).\n    'GetResultsFolder'  - (1,1) logical, when true the entire model\n                          folder produced by Dynare is moved back to the\n                          calling directory under the run name (default: false).\n    'RunName'           - (1,1) string, explicit name for the run folder.\n                          If not provided, a timestamped name will be used.\n    'Overwrite'         - (1,1) logical, if true an existing run with the \n                          same name will be removed (default: false).\n    'WorkingDir'        - (1,1) string, working folder to return to on\n                          completion. This must be an existing folder\n                          (default: pwd).\n    'ResultsDir'        - (1,1) string, folder to copy the results from the\n                          run (default: WorkingDir)\n    'DynareLocation'    - (1,1) string, Location of the dynare.m file. If\n                          dynare is already on path it can be omitted. Use\n                          this if you are running on a cluster with a\n                          different location for Dynare, or if you want to\n                          override your default installation.\n \n    Example:\n        [out, info] = <strong>runDynareModel<\/strong>(\"myModel.mod\", 'RunFolder', tempdir, ...\n            'Flags', \"nolog\", 'GetResultsFolder', true);\n \n    Outputs:\n        OUT  - structure containing workspace variables from the base\n               workspace after Dynare execution (or saved results).\n        INFO - the output returned by dynare(...) call.\n \n    Notes:\n      - NAME must refer to an existing file. Use full path or relative path.\n      - The function creates a temporary run folder and removes it on\n        function completion (unless GetResultsFolder is true, in which\n        case the Dynare-generated model folder is moved back to the caller\n        location under the run name).\n      - The function attempts to return workspace variables from the base\n        workspace; on older MATLAB releases it uses a temporary save\/load.\n \n    See also <a href=\"matlab:help dynare -displayBanner\">dynare<\/a>, <a href=\"matlab:help tempdir -displayBanner\">tempdir<\/a>, <a href=\"matlab:help copyfile -displayBanner\">copyfile<\/a>, <a href=\"matlab:help movefile -displayBanner\">movefile<\/a>, <a href=\"matlab:help rmdir -displayBanner\">rmdir<\/a>.\n \n    Copyright 2024 - 2026 The MathWorks, Inc.\n\n","truncated":false}}
%---
