function [out, info] = runDynareModel(name, nvp)
%RUNDYNAREMODEL Run a Dynare model in an isolated temporary folder.
%
%   [OUT, INFO] = runDynareModel(NAME) copies the Dynare model file specified
%   by NAME (a string filename or full path) into a running folder, runs
%   Dynare on that model, collects results into OUT, and returns the INFO
%   output from Dynare. By default a timestamped run folder is created in
%   the system temporary directory.
%
%   [...] = runDynareModel(NAME, Name,Value) specifies additional options
%   using name-value pair arguments. Valid name-value pairs are:
%
%   'AttachedFiles'     - (1,:) string, paths to additional files to copy
%                         into the run folder (each must exist).
%   'AttachedFolders'   - (1,:) string, paths to additional folders to copy
%                         into the run folder (each must exist).
%   'DynareLocation'    - (1,1) string, Location of the dynare.m file. If
%                         dynare is already on path it can be omitted. Use
%                         this if you are running on a cluster with a
%                         different location for Dynare, or if you want to
%                         override your default installation.
%   'Flags'             - (1,:) string, Dynare command-line flags passed
%                         to dynare (default: string.empty()).
%   'GetResultsFolder'  - (1,1) logical, when true the entire model
%                         folder produced by Dynare is moved back to the
%                         calling directory under the run name (default: false).
%   'Overwrite'         - (1,1) logical, if true an existing run with the 
%                         same name will be removed (default: false).
%   'ResultsDir'        - (1,1) string, folder to copy the results from the
%                         run (default: WorkingDir)
%   'RunFolder'         - (1,1) string, base folder in which to create the
%                         run folder (default: tempdir).
%   'RunName'           - (1,1) string, explicit name for the run folder.
%                         If not provided, a timestamped name will be used.
%   'WorkingDir'        - (1,1) string, working folder to return to on
%                         completion. This must be an existing folder
%                         (default: pwd).
%
%   Example:
%       [out, info] = runDynareModel("myModel.mod", 'RunFolder', tempdir, ...
%           'Flags', "nolog", 'GetResultsFolder', true);
%
%   Outputs:
%       OUT  - structure containing workspace variables from the base
%              workspace after Dynare execution (or saved results).
%       INFO - the output returned by dynare(...) call.
%
%   Notes:
%     - NAME must refer to an existing file. Use full path or relative path.
%     - The function creates a temporary run folder and removes it on
%       function completion (unless GetResultsFolder is true, in which
%       case the Dynare-generated model folder is moved back to the caller
%       location under the run name).
%     - The function attempts to return workspace variables from the base
%       workspace; on older MATLAB releases it uses a temporary save/load.
%
%   See also dynare, tempdir, copyfile, movefile, rmdir.
%
%   Copyright 2024 - 2026 The MathWorks, Inc.

arguments
    name %(1,1) string {mustBeFile}
    nvp.Flags (1,:) string = string.empty()
    nvp.AttachedFiles (1,:) string {mustBeFile} = string.empty()
    nvp.AttachedFolders (1,:) string {mustBeFolder} = string.empty()
    nvp.DynareLocation (1,1) string = string(missing)
    nvp.GetResultsFolder (1,1) logical = false
    nvp.Overwrite (1,1) logical = false
    nvp.ResultsDir (1,1) string = string(missing)
    nvp.RunFolder (1,1) string = tempdir
    nvp.RunName (1,1) string = string(missing)
    nvp.WorkingDir (1,1) string {mustBeFolder} = pwd
end

% Process filename
d = dir(name);
ModelName = d.name;
[~, ModelNameClean] = fileparts(ModelName);
ModelFolder = d.folder;

% Set experiment name
if ismissing(nvp.RunName)
    RunName = sprintf('%s_%s', ModelNameClean, string(datetime('now', 'Format','dd_MMM_uuuu_HH_mm_ss')));
else
    RunName = nvp.RunName;
end

% Set folders
if ismissing(nvp.ResultsDir)
    resultsDir = nvp.WorkingDir;
else
    resultsDir = nvp.ResultsDir;
    if ~isfolder(resultsDir)
        mkdir(resultsDir)        
    end
    d = dir(resultsDir);
    resultsDir = d(1).folder;
end

% Create running folder
tdir = fullfile(nvp.RunFolder, matlab.lang.internal.uuid);
if isfolder(tdir)
    error('This directory already exists, please choose a non-existing directory or leave default to use TEMP')
end
mkdir(tdir);

% Cleanup
cobj = onCleanup(@() cleanup(nvp.WorkingDir, tdir));

% Check results folder
if nvp.GetResultsFolder
    targetDir = fullfile(resultsDir, RunName);
    if isfolder(targetDir) 
        if nvp.Overwrite
            rmdir(targetDir, 's')
        else
            error('Results folder already exist, change the RunName or set Overwrite=true')
        end
    end
end

% Move model
copyfile(fullfile(ModelFolder, ModelName), tdir);

% Move supporting files
for i = 1 : numel(nvp.AttachedFiles)
    copyfile(nvp.AttachedFiles(i), tdir);
end

% Move supporting folders
for i = 1 : numel(nvp.AttachedFolders)
    copyfile(nvp.AttachedFolders(i), tdir);
end

% RunDynare
cd(tdir)

args = cellstr(nvp.Flags);
try    
    % Make sure that we add the right dynare to the path if supplied,
    % otherwise it is expected to be on path already.
    if ~ismissing(nvp.DynareLocation)
        if endsWith(nvp.DynareLocation, 'dynare.m')
            addpath(fileparts(nvp.DynareLocation));
        elseif endsWith(nvp.DynareLocation, 'matlab')
            addpath(nvp.DynareLocation)
        else
            addpath(fullfile(nvp.DynareLocation, 'matlab'));
        end
    end
    % We evaluate using "feval" because otherwise some dependency 
    % management would be attempted to move dynare
    info = feval('dynare', char(ModelName) ,  args{:}); %#ok<FVAL>
    out = dynutil.collectDynareResults();
    if nvp.GetResultsFolder
        collectModelFolder(ModelNameClean, resultsDir, RunName)
    end
catch e
    if nvp.GetResultsFolder
        collectModelFolder(ModelNameClean, resultsDir, RunName)
    end
    rethrow(e)
end

end

function cleanup(location, tdir)
    try
        cd(location)
    catch
        % If changing back fails, ignore to avoid masking original errors
    end
    if isfolder(tdir)
        rmdir(tdir, 's')
    end
end

function collectModelFolder(modelName, directory, runName)

arguments
    modelName
    directory
    runName
end

modelFolderLocal = fullfile(pwd, modelName);
if isfolder(modelFolderLocal) 
    movefile(modelFolderLocal, fullfile(directory, runName))
end

end