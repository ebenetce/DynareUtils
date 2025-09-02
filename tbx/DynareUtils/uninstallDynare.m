function uninstallDynare(Version)
    % UNINSTALLDYNARE Function to uninstall a specific version of Dynare
    %
    % Input Arguments:
    %     Version - version of Dynare to uninstall as a string

    arguments
        Version (1,1) string
    end
    clear mex %#ok<CLMEX> % Clear any compiled MEX functions
    available = dynutil.getDynareAddons(); % Retrieve available Dynare addons
    toRemove = available(available.Version == Version, :); % Filter addons to find the specified version
    if ~isempty(toRemove)
        matlab.addons.uninstall('dynare', toRemove.Version) % Uninstall the specified version of Dynare
        fprintf('Uninstalled Dynare %s\n', toRemove.Version) % Confirm uninstallation
    else
        fprintf('Unable to find this version, please see installed versions below:\n\n') % Notify if version not found
        disp(available) % Display available versions
    end
end