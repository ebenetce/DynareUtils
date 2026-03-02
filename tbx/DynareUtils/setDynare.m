function setDynare(version, nvp)
% SETDYNARE Set and enable a specified Dynare version
%
% Usage:
%   setDynare()                - sets the latest available Dynare version
%   setDynare(version)         - sets the specified Dynare version (string)
%   setDynare(version, Name, Value, ...)
%
% Inputs:
%   version    - Dynare version to set (string). Use missing or omit to
%                select the latest available version.
%
% Name-Value pairs:
%   'ZipTool'  - Full path to the zip/extractor executable used to
%                install Dynare (default: "C:\Program Files\7-Zip\7z.exe")
%
% Description:
%   setDynare ensures a specific Dynare release is installed and enabled
%   as a MATLAB addon. If no version is provided, the function selects
%   the latest available release returned by dynutil.getAllDynareVersions.
%
%   The function will:
%     - remove any manual Dynare installation from the MATLAB path,
%     - download and install the requested version if not already
%       available,
%     - enable the requested Dynare addon,
%     - verify the installation by calling "dynare help".
%
% Examples:
%   setDynare()                          % set latest Dynare
%   setDynare("5.4.4")                   % set Dynare 5.4.4
%   setDynare("5.4.4", 'ZipTool', p)     % set Dynare using custom zip tool
%
% See also dynutil.getAllDynareVersions, dynutil.getDynareAddons,
%          dynutil.downloadAndInstall, disableDynare, dynutil.clearManualInstall

arguments
    version (1,1) string = string(missing) % Define version argument with default
    nvp.ZipTool (1,1) string = "C:\Program Files\7-Zip\7z.exe"
end
clear mex %#ok<CLMEX>

% Get latest version on default
if ismissing(version)
    version = dynutil.getAllDynareVersions(); % Retrieve all available Dynare versions
    version = version(1); % Select the latest version
end

% Check if dynare is available
isDynareAvailable = which('dynare'); % Check if Dynare is in the path
[available, enabled] = dynutil.getDynareAddons(); % Get available and enabled Dynare addons

% Remove manual install (hard to manage)
if ~isempty(isDynareAvailable) && isempty(enabled)
    warning('Dynare was manually installed, removing from path')
    dynutil.clearManualInstall(); % Clear manual installation from path
end

% Check available versions
isVersionAvailable = available(available.Version == version, :); % Check if the requested version is available
if isempty(isVersionAvailable)
    try
        % Install if not available
        dynutil.downloadAndInstall(version, ZipTool = nvp.ZipTool) % Download and install the specified version
    catch e
        error('Error downloading Dynare. Please check the <a href="matlab:dynutil.getAllDynareVersions">available dynare versions</a>\n\nThe actual error was %s\n', e.message);
    end
else
    %Enable if already installed
    if isempty(enabled) || enabled.Version ~= version
        disableDynare(Silent = true) % To remove paths.
        matlab.addons.enableAddon("658a2ffd-f7d5-4170-bcb5-ac75a11196b9", version) % Enable the specified version of Dynare
    end
end
% Check
try
    dynare help % Attempt to run Dynare help to verify installation
catch e
    error('DynUtils:FailedToSetDynare',"Something went wrong, dynare not installed: " + e.message)
end
end