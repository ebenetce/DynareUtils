function createDynareExperiment(folder)
%CREATE DYNARE EXPERIMENT Create a Dynare experiment project in a folder
%   createDynareExperiment(FOLDER) creates a new Dynare experiment project
%   in the directory specified by FOLDER. FOLDER must be a scalar string
%   specifying the path to the destination folder. If the folder already
%   exists an error is raised.
%
%   Example:
%       createDynareExperiment("C:\Users\Me\DynareExperiment")
%
%   Inputs:
%       folder - (1,1) string scalar specifying the destination folder.
%
%   Errors:
%       DynareUtils:ExperimentFolderShouldNotExist - if the specified folder
%           already exists.
%
%   See also matlab.project.extractProject, isfolder, mkdir

arguments
    folder (1,1) string
end

if isfolder(folder)
    error('DynareUtils:ExperimentFolderShouldNotExist', ...
        'This folder already exists, please select a new folder to place the exeperiment')
end

mkdir(folder)

matlab.project.extractProject(fullfile(dynareUtilsRoot, 'tbx','experiment','DynareExperiment.mlproj'), folder);
experiments.internal.View('project',fullfile(folder, 'DynareExperiment.prj'));