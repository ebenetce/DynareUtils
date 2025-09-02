function clearManualInstall()
    % CLEARMANUALINSTALL Function to clear manual installation of Dynare
    %
    % This function removes the Dynare path from MATLAB if it exists.

    clear mex %#ok<CLMEX>
    if nargin == 0
        loc = which('dynare'); % Check if Dynare is available
    end
    if ~isempty(loc)
        dynutil.clearInstall(loc);
    end
end