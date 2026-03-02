function out = dynareParallel(modFile, nvp)
% DYNAREPARALLEL Function to run Dynare in parallel
%
% Input Arguments:
%     modFile - Name of the Dynare mod file to be processed
%     nvp - Name-value pairs for additional options
%         AdditionalFiles - Supporting files required for the mod file
%         Flags - Additional Dynare flags for execution
%         UseParallel - Boolean to specify if parallel processing should be used
%         GetResultsFolder - Boolean to specify if results folder should be retrieved
%
% Output Arguments:
%     out - Output from the Dynare execution
%
% For example:
% out = dynareParallel('fs2000.mod', AdditionalFiles = "fs2000_data.m", Flags = ["nograph", "nolog"], UseParallel = true);

arguments
    modFile (1,:) char {mustBeFile}                     % Mod Files
    nvp.AdditionalFiles (1,:) string = string.empty();  % Supporting files
    nvp.Flags (1,:) string = string.empty();            % Additional Dynare flags
    nvp.UseParallel (1,1) logical = true                % Whether or not to use parallel
    nvp.GetResultsFolder (1,1) logical = false          % Whether to bring the results folder
end

dynver = extractBefore(dynare_version, '.');
if dynver == '4'
    error('DynareUtils:NotSupportedFor4', 'This is not supported on Dynare 4.X and older versions')
elseif dynver == '7'
    warning('DynareUtils:BuiltInSupport', 'Dynare 7 supports parallel processing out of the box, please consider using "dynare" directly')
end

% Dynare dumps results in base workspace. clear it
evalin('base', 'clear');

% Record current directory.
here = pwd();

% Create TempDir to run the code
folder = tempname();
mkdir(folder);

% Cleanup tasks
cObj =  onCleanup(@() doCleanup(here, folder));

% Move files to temp folder
copyfile(modFile, folder);
files = nvp.AdditionalFiles;
if ~isempty(nvp.AdditionalFiles)
    for i = 1 : numel(files)
        file = files(i);
        if ~isfile(file)
            error('DynareUtils:NotFound','Unable To find file %s', file)
        end
        file = dir(file);
        copyfile(fullfile(file.folder, file.name), folder)
    end
end

% Move to temp folder
cd(folder);

% For running in parallel, we need to override certain functions
if nvp.UseParallel

    p = gcp('nocreate');
    if isempty(p)
        s = settings;
        if s.parallel.client.pool.AutoCreate.ActiveValue
            warning('DynareUtils:NoParallelEnvironmentAuto', 'Unable to find parallel environment, starting one by default')
        else
            warning('DynareUtils:NoParallelEnvironmentSerial', 'Unable to find parallel environment, running in serial')
        end
    end

    if isa(p, 'parallel.ThreadPool')
        error('DynareUtils:ThreadsNotAllowed', 'Threads cannot be used in Dynare')
    end

    % Copy files
    copyfile(fullfile(dynareUtilsRoot, dynver, '*'), folder)

end

% Call dynare
flags = cellstr(nvp.Flags);
[~, fname, ext] = fileparts(modFile);
dynare([fname, ext], flags{:});

% Load files if necessary
if nargout > 0
    out = dynutil.collectDynareResults();
end

if nvp.GetResultsFolder
    dest = fname+"_"+string(datetime('now', 'Format','ddMMMyyyyHHmmss'));
    movefile(fname, fullfile(here, dest))
end

end

function doCleanup(here, folder)

clear mex %#ok<CLMEX>
cd(here);
rmdir(folder, 's');

end