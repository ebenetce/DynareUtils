function setDynare(version, nvp)
    % SETDYNARE Function to set the specified version of Dynare
    %
    % Input Arguments:
    %     version - version of Dynare to set (default is missing)
    %
    % See also <a href="matlab:dynutil.getAllDynareVersions">dynare versions</a>
    
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
            matlab.addons.enableAddon('dynare', version) % Enable the specified version of Dynare
        end
    end
    % Check 
    try
        dynare help % Attempt to run Dynare help to verify installation
    catch e
        error('DynUtils:FailedToSetDynare',"Something went wrong, dynare not installed: " + e.message)    
    end
end