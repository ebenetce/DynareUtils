function uninstallDynare(Version)
    % UNINSTALLDYNARE Uninstall a specified Dynare addon version from MATLAB.
    %
    % Usage:
    %   uninstallDynare(Version)
    %
    % Input:
    %   Version  - A string scalar specifying the Dynare version to uninstall,
    %              for example "4.6.4".
    %
    % Behaviour:
    %   The function clears loaded MEX functions, queries the installed Dynare
    %   addons via dynutil.getDynareAddons(), and attempts to uninstall the
    %   addon whose Version matches the supplied Version string. If the
    %   requested version cannot be found the function lists currently
    %   available Dynare addon entries.
    %
    % Notes:
    %   - The function expects dynutil.getDynareAddons to return a table
    %     containing a 'Version' variable.
    %   - The uninstall call uses a fixed addon ID corresponding to the
    %     Dynare toolbox; this ID must be correct for the environment where
    %     the function is executed.
    %
    % Example:
    %   uninstallDynare("4.6.4")
    %
    % See also: matlab.addons.uninstall

    arguments
        Version (1,1) string
    end

    clear mex %#ok<CLMEX> % Clear any compiled MEX functions

    % Retrieve available Dynare addons
    available = dynutil.getDynareAddons();

    % Find matching addon(s)
    toRemove = available(available.Version == Version, :);

    if ~isempty(toRemove)
        % Uninstall the specified version of Dynare using the known addon ID
        matlab.addons.uninstall("658a2ffd-f7d5-4170-bcb5-ac75a11196b9", toRemove.Version);
        fprintf('Uninstalled Dynare %s\n', toRemove.Version);
    else
        fprintf('Unable to find Dynare version "%s". Installed versions are:\n\n', Version);
        disp(available);
    end
end