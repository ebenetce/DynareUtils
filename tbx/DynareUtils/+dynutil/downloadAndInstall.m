function downloadAndInstall(version)

% Download dynare
folder = tempname();
mkdir(folder)
cleanupObj = onCleanup(@() rmdir(folder, 's'));
if ispc
    fprintf('Downloading Dynare...\n')
    url = sprintf('https://www.dynare.org/release/windows-zip/dynare-%s-win.zip', version);
    fileName = fullfile(folder, "dynare.zip");
    websave(fileName, url);    
    fprintf('Extracting files...\n')
    unzip(fileName, fullfile(folder, "extracted"));
else
    error('DynUtils:LinuxAndMacNotSupported','This tool is not yet ready for Linux or Mac')
end

% package
fprintf('Building toolbox...\n')
d = dir(fullfile(folder, "extracted"));
finalLocation = fullfile(d(3).folder, d(3).name);
out = dynutil.packageDynare(finalLocation, version);

% install
fprintf('Installing...\n')
matlab.addons.install(out, 'add');
delete(out)