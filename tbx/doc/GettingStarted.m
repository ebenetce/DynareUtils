%[text] # Dynare Utils
%[text] A toolbox with various utilities to assist with the use of Dynare
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] ## Dynare version management
%[text] The toolbox allows setting up Dynare for you, for example, if you run:
setDynare('6.5')
%[text] It will download Dynare and install it as a toolbox in MATLAB. You can also use some additional utilities in case you need to swap versions:
%[text] - **`disableDynare`****()**: Disables the current version of Dynare without removing it from the system
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
%[text] ## Dynare jobs
%[text] There are multiple ways to submit Dynare jobs and it greatly depends on whether you do it locally or in a cluster. At this time, doing this in parallel is not well supported.
%[text] ### Local
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
