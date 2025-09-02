function job = submitDynareJob(c,modelName,nvp)

arguments
    c
    modelName          (1,1) string {mustBeFile}
    nvp.DynareLocation (1,1) string
    nvp.DynareFlags    (1,:) string = string.empty()
    nvp.AttachedFiles  (1,:) string = string.empty()
end

d = dir(modelName);
modelFullPath = string(fullfile(d.folder, d.name));

if isa(c, 'parallel.cluster.Local')
    location = fileparts(which('dynare'));
    if isempty(location)
        error('DynareUtils:submitDynare:NotFound','Dynare not found, please call setDynare first')
    end
else
    location = fullfile(nvp.DynareLocation, 'matlab');
    if isfolder(nvp.DynareLocation)
        error('DynareUtils:submitDynare:NotFoundInCluster', 'Please provide the locaiton of the "dynare" folder in the cluster')
    end
end

job = batch(c, ... % cluster where we are running
    @myDynare, ... % Function to run (see below)
    1, ...         % Number of outputs
    cellstr([modelFullPath, nvp.DynareFlags]), ... % <MODIFY> Call to "dynare modelName noclearall nowarn"
    AutoAddClientPath=false, ...            % Don't try to replicate your path in the cluster, dynare probably exists in a different place
    AutoAttachFiles=false, ...              % With Dynare auto-attaching never works, needs to do manually
    CurrentFolder = '.', ...                % Folder where the cluster will run, leave as default.
    AttachedFiles=cellstr([modelFullPath, nvp.AttachedFiles]), ... % Files that the model needs to run. For example .mod, steadstate, .mat, etc. The model is included by default.
    AdditionalPaths=location); % Location of Dynare in the cluster. This is the same as "addpath( ... )"

end

function out = myDynare(modelName, varargin)

[~,mname, mext] = fileparts(modelName);
modelName = [char(mname), char(mext)];

% The files are not transferred to the current folder.
% Get the location of all your transferred files
fileLocation = getAttachedFilesFolder(modelName);

if ~isempty(fileLocation) % This means that we are on the server
    % cd to the folder containing the model
    cd(fileLocation);
else % we are running locally,
    % run in a temp dir to avoid overlaps
    tfolder = tempname;
    mkdir(tfolder)

    % move files to temp dir
    j = getCurrentJob;
    for i = 1 : numel(j.AttachedFiles)
        copyfile(j.AttachedFiles{i}, tfolder);
    end
    % Remove tempdir after job
    cobj = onCleanup(@() rmdir(tfolder, 's'));
    % Move to temp dir to run dynare
    cd(tfolder)
end

% Export Function results
% Capture the results. Dynare dumps everything in the base workspace. The
% easiest way is to save everything and load it back into a struct. But if
% you know what variables you need, you can simply do this manually.
dynare(modelName, varargin{:});
out = dynutil.collectDynareResults();
end