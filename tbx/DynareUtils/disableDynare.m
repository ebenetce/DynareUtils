function disableDynare(nvp)
%DISABLEDYNARE Disable Dynare addon and clear manual installs.
%
%   DISABLEDYNARE disables Dynare (if installed and enabled) and clears any
%   manual Dynare installs from the MATLAB path. If Dynare is not available
%   the function prints a message.
%
%   DISABLEDYNARE(Name,Value) accepts the following name-value pairs:
%     'Silent'  - logical scalar. If true, suppresses informational
%                 printed output. Default is false.
%
%   The function performs these steps:
%     1) Calls clear mex to remove compiled MEX files. 2) Checks for the
%     presence of Dynare on the MATLAB path. 3) If Dynare is not present,
%     optionally prints a message and returns. 4) If Dynare is present,
%     queries available and enabled Dynare addons
%        via dynutil.getDynareAddons().
%     5) If no enabled addon is found it attempts to clear manual installs.
%     6) If an enabled addon is present, disables the addon, clears the
%        install, and verifies that Dynare is no longer on the path.
%
%   Notes:
%     - This function relies on helper utilities in the dynutil package:
%       dynutil.getDynareAddons, dynutil.clearManualInstall,
%       dynutil.clearInstall. These functions must be on the MATLAB path.
%     - The function uses a hard-coded addon identifier for the Dynare
%       addon. Adjust the identifier if a different addon ID is required.
%
%   Example:
%     disableDynare('Silent',true)
%
%   See also clear, which, matlab.addons.disableAddon

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