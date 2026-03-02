function out = collectDynareResults()
if isMATLABReleaseOlderThan("R2025a")
    tname = matlab.lang.internal.uuid;
    saveCommand = sprintf("save %s.mat", tname);
    evalin('base', saveCommand);
    out = load(tname +".mat");
    try
        delete(tname + ".mat");
    catch
    end
else
    out = matlab.lang.Workspace.baseWorkspace;
end
end