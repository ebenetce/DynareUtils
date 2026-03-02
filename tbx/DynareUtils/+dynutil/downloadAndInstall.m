function downloadAndInstall(version, nvp)

arguments
    version
    nvp.ZipTool (1,1) string = "C:\Program Files\7-Zip\7z.exe"
end

% Download dynare
folder = tempname();
mkdir(folder)
cleanupObj = onCleanup(@() rmdir(folder, 's'));
if ispc
    if ~isfile(nvp.ZipTool)
        error('DynareUtils:SevenZipNecessary', ...
            'Dynare for Windows are packaged as 7z files, please provide the location of 7z.exe, with setDynare(..., ZipTool = "C:/Path/To/7z.exe")')    
    end

    fprintf('Downloading Dynare %s...\n', version)
    url = sprintf('https://www.dynare.org/release/windows-7z/dynare-%s-win.7z', version);
    fileName = fullfile(folder, "dynare.7z");
    websave(fileName, url);
    fprintf('Extracting files...\n')
    cmd = sprintf('"%s" x "%s" -o"%s"', nvp.ZipTool, fileName, fullfile(folder, 'extracted'));
    [status, msg] = system(cmd);
    if status ~= 0
        error(msg)
    end
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