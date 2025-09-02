function clearInstall(loc, nvp)

arguments
    loc (1,1) string {mustBeFile}
    nvp.Silent (1,1) logical = false;
end

clear mex %#ok<CLMEX>

dynpath = fileparts(fileparts(loc));
fld = dir(dynpath); % Get directory contents
fld = fld([fld.isdir]); % Filter to keep only directories
p = matlabpath(); % Get current MATLAB path
% remove . and ..
for i = 1 : numel(fld)
    fname = fullfile(fld(i).folder, fld(i).name); % Construct full folder name
    if contains(p, fname) % Check if folder is in MATLAB path
        rmpath(fname); % Remove folder from MATLAB path
    end
end
if ~nvp.Silent
    fprintf('Cleared manual install..\n') % Notify user of completion
end
end