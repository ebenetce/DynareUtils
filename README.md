
<a id="TMP_5ed8"></a>

# Dynare Utils

A toolbox with various utilities to assist with the use of Dynare

<!-- Begin Toc -->

## Table of Contents
&emsp;[Dynare version management](#TMP_3884)
 
&emsp;[Speeding up Dynare estimations with Parallel computing](#TMP_63c8)
 
&emsp;&emsp;[Example: Markov Chains in parallel](#TMP_57e6)
 
&emsp;&emsp;[Example: Posterior Mode Optimization using Parallel computing](#TMP_009d)
 
&emsp;[Running Dynare jobs and experiments](#TMP_95a6)
 
&emsp;&emsp;[Local machine](#TMP_8c72)
 
&emsp;&emsp;[Cluster](#TMP_074a)
 
&emsp;&emsp;[Experiments](#TMP_3b14)
 
&emsp;[Detailed solution](#TMP_1f38)
 
&emsp;&emsp;[Issue](#TMP_7731)
 
&emsp;&emsp;[Solution](#TMP_4faf)
 
<!-- End Toc -->
<a id="TMP_3884"></a>

# Dynare version management

The toolbox allows setting up Dynare for you, for example, if you run:

```matlab
setDynare()
```

It will download the latest version of Dynare and install it as a toolbox in MATLAB. You can optionally specify the version as:

```
setDynare('5.5')
```

In Windows, Dynare is packaged as 7z files. To install it with this tool you will need 7z installed. The tool assumes a default location, but you can also specify:

```
setDynare('5.5', ZipTool = "C:/Path/To/7z.exe")
```

There are some additional utilities in case you need to swap versions:

-  **`disableDynare`****\*\*\*\*()**: Disables the current version of Dynare without removing it from the system 
-  **`uninstallDynare(<version>)`**: Completely removes the version of Dynare from your computer 

Please note that if you install Dynare separately the toolbox attempts to help, but the results can be incorrect. It is recommended that either you manually set Dynare, or you entirely manage it via this toolbox, but not both at the same time.

<a id="TMP_63c8"></a>

# Speeding up Dynare estimations with Parallel computing 

This toolbox enables running certain Dynare workflows using parallel computing. Many of them are already enabled in Dynare 7, so please check if that is an option before reading further.


For those workflows where parallel computing is indeed possible (see examples below), the goal is to be able to do as follows:

<a id="TMP_5026"></a>

**1. Start a parallel environment**

```
parpool Processes
```

**2. Run your model** 


The function "**dynareParallel**" will safely run your model using parallel computing toolbox

```
dynareParallel('yourModFile.mod')
```

**3. Pass additional options when necessary**

<a id="H_5962"></a>

Dynare models can get very complicated, require multiple files and produce a variety of results. This function accepts some additional options to manage those use cases:

```
out = dynareParallel('yourModFile.mod', ...                               % Main mod file, can be in any folder
                     Flags = ["nowarn", "nolog"]), ...                    % standard options of the Dynare command
                     AttachedFiles = ["steadystate.m", "data.mat"], ...   % additional files needed for your model
                     UseParallel = true, ...                              % whether to use parallel or not. 
                     GetResultsFolder = false);                           % Whether to collect the folder with Markov chain results and other model outputs 

% The out variable is a struct with the workspace after running Dynare.
```
<a id="TMP_57e6"></a>

## Example: Markov Chains in parallel

This applies if you are estimating multiple Markov Chains in parallel. This would be a sample estimation:

```
estimation(order=1, datafile=fs2000_data, loglinear,logdata, mode_compute=4, mh_replic=20000, nodiagnostic,
mh_nblocks=2, mh_jscale=0.8, mode_check);
```

In this case 2 chains are estimated, so you probably want to create a parpool of this type:

```
c = parcluster('Processes');
c.NumThreads = <NumberOfCores>/<NumberOfChains>;
parpool(c, <NumberOfChains>)
out = dynareParallel('yourModel.mod')
```
<a id="TMP_009d"></a>

## Example: Posterior Mode Optimization using Parallel computing 
<a id="TMP_46da"></a>

This applies if you have an estimation block in your model file with the following block:

```
estimation(optim=('UseParallel', true), datafile=usmodel_data,
mode_compute=1,first_obs=1, presample=4,lik_init=2,prefilter=0,
mh_replic=0,mh_nblocks=2,mh_jscale=0.20,mh_drop=0.2, nograph, nodiagnostic, tex);
```

**`mode_compute = 1`** establishes that you are using "**`fmincon`**". This is a built\-in algorithm and it accepts a parallel flag to speed up the process. To enable this, you need to run it as follows:

```
parpool('Processes')
out = dynareParallel('model_file.mod')
```
<a id="TMP_95a6"></a>

# Running Dynare jobs and experiments

There are multiple ways to submit Dynare jobs and it greatly depends on whether you do it locally or in a cluster. 


**Note:** If you want to run Dynare in parallel using Jobs, please consider using Dynare 7 or newer

<a id="TMP_8c72"></a>

## Local machine

The easiest way to run a Dynare job is to use parfeval, this will directly submit the Dynare calculations to a local worker in your machine. However, it is highly encouraged that you submit jobs using the built\-in wrapper. Otherwise, simultaneous dynare jobs might override the results. This function has the additional advantage that does not require the MOD file to exist in the same folder where you are launching the job.

```
fcn = j = parfeval( @(x) runDynareModel(x, Flags = ["nolog", "nowarn"], CollectResultsFolder = false) )
j = parfeval(fcn, 2, "C:\Path\To\yourmodel.mod" )
```

Once the job is done, you can then see the Diary

```
j.Diary
```

Or collect the outputs:

```
out = fetchOutputs(j)
```

If you have selected "**`GetResultsFolder = true`**" the folder with the results of the run will be copied to current folder, or the results folder specified in the inputs. For more information on this function, please run:

```matlab
help runDynareModel
```

```matlabTextOutput
 runDynareModel Run a Dynare model in an isolated temporary folder.
 
    [OUT, INFO] = runDynareModel(NAME) copies the Dynare model file specified
    by NAME (a string filename or full path) into a running folder, runs
    Dynare on that model, collects results into OUT, and returns the INFO
    output from Dynare. By default a timestamped run folder is created in
    the system temporary directory.
 
    [...] = runDynareModel(NAME, Name,Value) specifies additional options
    using name-value pair arguments. Valid name-value pairs are:
 
    'Flags'             - (1,:) string, Dynare command-line flags passed
                          to dynare (default: string.empty()).
    'AdditionalFiles'   - (1,:) string, paths to additional files to copy
                          into the run folder (each must exist).
    'AdditionalFolders' - (1,:) string, paths to additional folders to copy
                          into the run folder (each must exist).
    'RunFolder'         - (1,1) string, base folder in which to create the
                          run folder (default: tempdir).
    'GetResultsFolder'  - (1,1) logical, when true the entire model
                          folder produced by Dynare is moved back to the
                          calling directory under the run name (default: false).
    'RunName'           - (1,1) string, explicit name for the run folder.
                          If not provided, a timestamped name will be used.
    'Overwrite'         - (1,1) logical, if true an existing run with the 
                          same name will be removed (default: false).
    'WorkingDir'        - (1,1) string, working folder to return to on
                          completion. This must be an existing folder
                          (default: pwd).
    'ResultsDir'        - (1,1) string, folder to copy the results from the
                          run (default: WorkingDir)
    'DynareLocation'    - (1,1) string, Location of the dynare.m file. If
                          dynare is already on path it can be omitted. Use
                          this if you are running on a cluster with a
                          different location for Dynare, or if you want to
                          override your default installation.
 
    Example:
        [out, info] = runDynareModel("myModel.mod", 'RunFolder', tempdir, ...
            'Flags', "nolog", 'GetResultsFolder', true);
 
    Outputs:
        OUT  - structure containing workspace variables from the base
               workspace after Dynare execution (or saved results).
        INFO - the output returned by dynare(...) call.
 
    Notes:
      - NAME must refer to an existing file. Use full path or relative path.
      - The function creates a temporary run folder and removes it on
        function completion (unless GetResultsFolder is true, in which
        case the Dynare-generated model folder is moved back to the caller
        location under the run name).
      - The function attempts to return workspace variables from the base
        workspace; on older MATLAB releases it uses a temporary save/load.
 
    See also dynare, tempdir, copyfile, movefile, rmdir.
 
    Copyright 2024 - 2026 The MathWorks, Inc.
```

<a id="TMP_074a"></a>

## Cluster

The same function can help in the the submission of a Dynare job into a cluster, you can run this function in combination with "batch" as follows

```
ModelFile = 'C:/path/to/agtrend.mod';
DyL = "/opt/dynare/" % For a linux installation
fcn = @() runDynareModel(ModelFile, Flags = ["nolog", "nowarn"], DynareLocation = DyL);

c = parcluster('ClusterName');
j = batch(c, fcn, 1, {}, AttachedFiles = ModelFile)
```

Note that we choose to specify the location of Dynare in the cluster as this is probably different than our own (it might not be even the same OS). 

<a id="TMP_3b14"></a>

## Experiments

When you want to run something like a parameter sweep, it can be useful to create an experiment to easily track inputs and outputs. You can even use parallel computing to set your experiment suite and run it in parallel within your own computer or submit it into a cluster. An experienced Dynare user might be able to create an experiment on their own. However, the toolbox has the following utility function to give you a template experiment ready to go such that you only need to edit your MOD file into it.

```
createDynareExperiment(pwd)
```
<a id="TMP_1f38"></a>

# Detailed solution
<a id="TMP_7731"></a>

## Issue

The problem is the use of persistent variables. The code relies on having to initialize certain functions. This is local to the MATLAB session and is not taken into account in the parallel workers.


If we look at the execution profile below, fmincon calls a function called "**`priordens`**" (marked in red) and a second one "**`dyn_first_order_solver`**" that heavily use persistent variables to be more efficient. 

```
function [logged_prior_density, dlprior, d2lprior, info] = priordens(x, pshape, p6, p7, p3, p4, initialization)

persistent id1 id2 id3 id4 id5 id6 id8
persistent tt1 tt2 tt3 tt4 tt5 tt6 tt8
```

The problem is that instead of initializing the function the first time is called, Dynare relies in two calls 

-  A first call to refresh the functions 
-  A second call to initialize the persistence. 

This will not be translated to the workers since each has its own copy of the functions and their memory.

<a id="TMP_4faf"></a>

## Solution

If the solution above does not work or is lacking functionality. This is the actual solution:

<a id="H_6317"></a>

**1. Override some Dynare functions**


Navigate to the folder below and then into the one corresponding to the right Dynare version

```matlab
dynareUtilsRoot
```

Copy the contents of that folder in the same folder where you have the .MOD file. For the case of Dynare 6.x, this should be:

-  global\_initialization.m 
-  posterior\_sampler\_core.m 
-  set\_dynare\_seed.m 
-  set\_prior.m 
<a id="H_1c5d"></a>

**2. Start a parallel environment**


For a local run, you can do this:

```
parpool('Processes')
```

**Tips**

-  Do not start more Processes than Chains. If you have only 2 chains do this: 
```
parpool('Processes', 2)
```
-  If you have more cores than chains. You can increase the speed by making sure that NumProcesses x NumThreads = NumCores 
```
c = parcluster('Processes')
c.NumThreads = 2
parpool(c, 2)
```
<a id="H_3ee0"></a>

**3. Call Dynare**


After you finished 1 and 2, call Dynare normally.

```
dynare fs2000.mod
```

This should run the Markov chains in parallel and the results should match exactly. 

