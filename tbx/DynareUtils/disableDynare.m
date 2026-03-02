function disableDynare(nvp)
    % DISABLEDYNARE Function to disable the Dynare addon in MATLAB
    %
    % This function checks if Dynare is available and disables it if it is
    % currently enabled. If Dynare is not available, it provides a message
    % to the user.

    arguments
        nvp.Silent (1,1) logical = false
    end

    clear mex; %#ok<CLMEX> % Clear any compiled MEX files
    isDynareAvailable = which('dynare'); % Check if Dynare is available
    if isempty(isDynareAvailable)
        doPrint('Dynare is not available, nothing to do.\n', nvp.Silent) % Inform user Dynare is not available
        return
    end
    if ~isempty(isDynareAvailable)
        [available, enabled] = dynutil.getDynareAddons(); % Get available and enabled Dynare addons
        if isempty(enabled)
            % Warn user if Dynare is not enabled or has been manually added to the path
            warning('DynareUtils:ManualInstall', "Version %s is not enabled or has been manually added ot the path. Attempting to remove manual install", Version)
            dynutil.clearManualInstall(); % Clear any manual installations
            return
        end    
        matlab.addons.disableAddon("658a2ffd-f7d5-4170-bcb5-ac75a11196b9", enabled.Version) % Disable the enabled Dynare addon
        dynutil.clearInstall(isDynareAvailable, Silent = true) % Clear paths
        d = which('dynare'); % Check again if Dynare is available
        if isempty(d)
            % Inform user that Dynare is no longer available and list installed versions
            doPrint('Dynare is no longer available, installed verisons include:\n\n', nvp.Silent)
            if ~nvp.Silent
                disp(sort(available.Version, 1, "descend")) % Display available versions in descending order
            end
            doPrint('Please call setDynare(<version>) to enable one of the versions above or download and install a new version\n', nvp.Silent) % Instructions for the user
        end
    end
end

function doPrint(text , silent, varargin)

arguments
    text   (1,1) string
    silent (1,1) logical = true
end

arguments (Repeating)
    varargin
end

if ~silent
    fprintf(text, varargin{:});
end

end