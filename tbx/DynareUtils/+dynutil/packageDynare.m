function out = packageDynare(location, version)

arguments
    location (1,1) string {mustBeFolder}
    version (1,1) string
end

% Create MLTBX
opts = matlab.addons.toolbox.ToolboxOptions(location,"658a2ffd-f7d5-4170-bcb5-ac75a11196b9", ...
    ToolboxMatlabPath = fullfile(location, 'matlab'));

opts.OutputFile = "dynare.mltbx";
opts.AuthorName = 'Dynare Team';
opts.Description = "Solves, simulates and estimates a wide class of economic models";
opts.SupportedPlatforms.MatlabOnline = false;
opts.SupportedPlatforms.Maci64 = ismac;
opts.SupportedPlatforms.Glnxa64 = isunix;
opts.SupportedPlatforms.Win64 = ispc;
opts.ToolboxVersion = version;
opts.ToolboxName = 'dynare';
matlab.addons.toolbox.packageToolbox(opts)

out = opts.OutputFile;