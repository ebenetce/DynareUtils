%[text] # Dynare Utils
%[text] A toolbox with various utilities to assist with the use of Dynare
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] ## Dynare version management
%[text] The toolbox allows setting up Dynare for you, for example, if you run:
setDynare()
%[text] It will download the latest version of Dynare and install it as a toolbox in MATLAB. You can optionally specify the version as:
%[text] ```matlabCodeExample
%[text] setDynare('5.5')
%[text] ```
%[text] In Windows, Dynare is packaged as 7z files. To install it with this tool you will need 7z installed. The tool assumes a default location, but you can also specify:
%[text] ```matlabCodeExample
%[text] setDynare('5.5', ZipTool = "C:/Path/To/7z.exe")
%[text] ```
%[text] There are some additional utilities in case you need to swap versions:
%[text] - **`disableDynare`****()**: Disables the current version of Dynare without removing it from the system
%[text] - **`uninstallDynare(<version>)`**: Completely removes the version of Dynare from your computer \
%[text] Please note that if you install Dynare separately the toolbox attempts to help, but the results can be incorrect. It is recommended that either you manually set Dynare, or you entirely manage it via this toolbox, but not both at the same time.
%%
%[text] ## Speeding up Dynare estimations with Parallel computing 
%[text] ### Requirements
%[text] - MATLAB
%[text] - Dynare 5 - 6
%[text] - Parallel Computing toolbox \
%%
%[text] ### Quick start
%[text] This toolbox enables running certain Dynare workflows using parallel computing. 
%[text] **Note: Dynare 7 contains native parallelization for many workflows. Use** **`dynareParallel`** **only when native Dynare parallelism does not apply.**
%[text] For those workflows where parallel computing is indeed possible (see examples below), the goal is to be able to do as follows:
%[text] %[text:anchor:TMP_5026] **1. Start a parallel environment**
%[text] ```matlabCodeExample
%[text] parpool Processes
%[text] ```
%[text] **2. Run your model** 
%[text] The function "**dynareParallel**" will safely run your model using parallel computing toolbox
%[text] ```matlabCodeExample
%[text] out = dynareParallel('yourModFile.mod')
%[text] ```
%[text] This function will:
%[text] - Run the Dynare call in a sandboxed temporary directory
%[text] - Isolation of outputs to avoid collisions
%[text] - Copying dependencies (`AttachedFiles` / `AttachedFolders`)
%[text] - Returning the base workspace as a **`struct`** in `out` \
%%
%[text] **3. Pass additional options when necessary**
%[text] %[text:anchor:H_5962] Dynare models can get very complicated, require multiple files and produce a variety of results. This function accepts some additional options to manage those use cases:
%[text] ```matlabCodeExample
%[text] out = dynareParallel('yourModFile.mod', ...                               % Main mod file, can be in any folder
%[text]                      Flags = ["nowarn", "nolog"]), ...                    % standard options of the Dynare command
%[text]                      AttachedFiles = ["steadystate.m", "data.mat"], ...   % additional files needed for your model
%[text]                      UseParallel = true, ...                              % whether to use parallel computing or not. 
%[text]                      GetResultsFolder = false);                           % Whether to collect the folder with Markov chain results and other model outputs 
%[text] 
%[text] % The out variable is a struct with the workspace after running Dynare.
%[text] ```
%%
%[text] ### Example: Markov Chains in parallel
%[text] This applies if you are estimating multiple Markov Chains in parallel. This would be a sample estimation:
%[text] ```matlabCodeExample
%[text] estimation(order=1, datafile=fs2000_data, loglinear,logdata, mode_compute=4, mh_replic=20000, nodiagnostic,
%[text] mh_nblocks=2, mh_jscale=0.8, mode_check);
%[text] ```
%[text] In this case 2 chains are estimated, so you probably want to create a parpool where the number of workers matches the number of mh\_blocks:
%[text] ```matlabCodeExample
%[text] c = parcluster('Processes');
%[text] c.NumThreads = floor(<NumberOfCores>/<NumberOfChains>);
%[text] parpool(c, <NumberOfChains>)
%[text] 
%[text] out = dynareParallel('yourModel.mod')
%[text] ```
%[text] ### Example: Posterior Mode Optimization using Parallel computing 
%[text] %[text:anchor:TMP_46da] This applies if you have an estimation block in your model file with the following block:
%[text] ```
%[text] estimation(optim=('UseParallel', true), datafile=usmodel_data,
%[text] mode_compute=1,first_obs=1, presample=4,lik_init=2,prefilter=0,
%[text] mh_replic=0,mh_nblocks=2,mh_jscale=0.20,mh_drop=0.2, nograph, nodiagnostic, tex);
%[text] ```
%[text] **`mode_compute = 1`** establishes that you are using "**`fmincon`**". This is a built-in algorithm that uses **finite difference gradients**, which are expensive and benefit from parallelism. Hence, it accepts a parallel flag to speed up the process. To enable this, you need to run it as follows:
%[text] ```matlabCodeExample
%[text] parpool('Processes')
%[text] out = dynareParallel('model_file.mod')
%[text] ```
%%
%[text] ## Running Dynare jobs and experiments
%[text] There are multiple ways to submit Dynare jobs and it greatly depends on whether you do it locally or in a cluster. 
%[text] **Note:** If you want to run Dynare in parallel using Jobs, please consider using Dynare 7 or newer
%[text] ### Local machine
%[text] The easiest way to run a Dynare job is to use parfeval, this will directly submit the Dynare calculations to a local worker in your machine. However, it is highly encouraged that you submit jobs using the built-in wrapper. Otherwise, simultaneous Dynare jobs might override the results. This function has the additional advantage that does not require the MOD file to exist in the same folder where you are launching the job.
%[text] ```matlabCodeExample
%[text] parpool('Processes',1)
%[text] fcn = @(x) runDynareModel(x, Flags = ["nolog", "nowarn"], GetResultsFolder = false)
%[text] j = parfeval(fcn, 2, fullfile("Path","To","yourmodel.mod") )
%[text] ```
%[text] Once the job is done, you can then see the Diary
%[text] ```matlabCodeExample
%[text] j.Diary
%[text] ```
%[text] Or collect the outputs:
%[text] ```matlabCodeExample
%[text] [out, info] = fetchOutputs(j)
%[text] ```
%[text] - `out` contains the base workspace state after Dynare runs.
%[text] - `info` contains Dynare's internal return structure. \
%[text] If you have selected "**`GetResultsFolder = true`**" the folder with the results of the run will be copied to current folder, or the results folder specified in the inputs. For more information on this function, please run:
help runDynareModel %[output:68d14b73]
%%
%[text] ### Cluster
%[text] The same function can help in the the submission of a Dynare job into a cluster, you can run this function in combination with "batch" as follows
%[text] ```matlabCodeExample
%[text] ModelFile = 'C:/path/to/agtrend.mod';
%[text] DyL = "/opt/dynare/" % For a linux installation
%[text] fcn = @() runDynareModel(ModelFile, Flags = ["nolog", "nowarn"], DynareLocation = DyL);
%[text] 
%[text] c = parcluster('ClusterName');
%[text] j = batch(c, fcn, 1, {}, AttachedFiles = ModelFile)
%[text] ```
%[text] Note that we choose to specify the location of Dynare in the cluster as this is probably different than our own (it might not be even the same OS). 
%%
%[text] ### Experiments
%[text] When you want to run something like a parameter sweep, it can be useful to create an experiment to easily track inputs and outputs. You can even use parallel computing to set your experiment suite and run it in parallel within your own computer or submit it into a cluster. An experienced Dynare user might be able to create an experiment on their own. However, the toolbox has the following utility function to give you a template experiment ready to go such that you only need to edit your MOD file into it.
%[text] ```matlabCodeExample
%[text] createDynareExperiment(pwd)
%[text] ```
%[text] `createDynareExperiment` produces a standard experiment harness including scripts for parameter sweeps, metadata tracking, and (optionally) batch submission.
%%
%[text] ## Detailed solution
%[text] ### Issue
%[text] Dynare 5.x and 6.x uses persistent variables in some internal functions. These persist only within the MATLAB client session not on parallel workers creating inconsistent results in parallel mode.
%[text] The code relies on having to initialize certain functions. This is local to the MATLAB session and is not taken into account in the parallel workers.
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
%[text] This works because the new functions will take precedence over the internal ones in Dynare.
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
%   data: {"dataType":"text","outputData":{"text":" <strong>runDynareModel<\/strong> Run a Dynare model in an isolated temporary folder.\n \n    [OUT, INFO] = <strong>runDynareModel<\/strong>(NAME) copies the Dynare model file specified\n    by NAME (a string filename or full path) into a running folder, runs\n    Dynare on that model, collects results into OUT, and returns the INFO\n    output from Dynare. By default a timestamped run folder is created in\n    the system temporary directory.\n \n    [...] = <strong>runDynareModel<\/strong>(NAME, Name,Value) specifies additional options\n    using name-value pair arguments. Valid name-value pairs are:\n \n    'AttachedFiles'     - (1,:) string, paths to additional files to copy\n                          into the run folder (each must exist).\n    'AttachedFolders'   - (1,:) string, paths to additional folders to copy\n                          into the run folder (each must exist).\n    'DynareLocation'    - (1,1) string, Location of the dynare.m file. If\n                          dynare is already on path it can be omitted. Use\n                          this if you are running on a cluster with a\n                          different location for Dynare, or if you want to\n                          override your default installation.\n    'Flags'             - (1,:) string, Dynare command-line flags passed\n                          to dynare (default: string.empty()).\n    'GetResultsFolder'  - (1,1) logical, when true the entire model\n                          folder produced by Dynare is moved back to the\n                          calling directory under the run name (default: false).\n    'Overwrite'         - (1,1) logical, if true an existing run with the \n                          same name will be removed (default: false).\n    'ResultsDir'        - (1,1) string, folder to copy the results from the\n                          run (default: WorkingDir)\n    'RunFolder'         - (1,1) string, base folder in which to create the\n                          run folder (default: tempdir).\n    'RunName'           - (1,1) string, explicit name for the run folder.\n                          If not provided, a timestamped name will be used.\n    'WorkingDir'        - (1,1) string, working folder to return to on\n                          completion. This must be an existing folder\n                          (default: pwd).\n \n    Example:\n        [out, info] = <strong>runDynareModel<\/strong>(\"myModel.mod\", 'RunFolder', tempdir, ...\n            'Flags', \"nolog\", 'GetResultsFolder', true);\n \n    Outputs:\n        OUT  - structure containing workspace variables from the base\n               workspace after Dynare execution (or saved results).\n        INFO - the output returned by dynare(...) call.\n \n    Notes:\n      - NAME must refer to an existing file. Use full path or relative path.\n      - The function creates a temporary run folder and removes it on\n        function completion (unless GetResultsFolder is true, in which\n        case the Dynare-generated model folder is moved back to the caller\n        location under the run name).\n      - The function attempts to return workspace variables from the base\n        workspace; on older MATLAB releases it uses a temporary save\/load.\n \n    See also dynare, <a href=\"matlab:help tempdir -displayBanner\">tempdir<\/a>, <a href=\"matlab:help copyfile -displayBanner\">copyfile<\/a>, <a href=\"matlab:help movefile -displayBanner\">movefile<\/a>, <a href=\"matlab:help rmdir -displayBanner\">rmdir<\/a>.\n \n    Copyright 2024 - 2026 The MathWorks, Inc.\n\n","truncated":false}}
%---
