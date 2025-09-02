function out = collectDynareResults()
if isMATLABReleaseOlderThan("R2025a")
    tname = matlab.lang.internal.uuid;
    saveCommand = sprintf("save %s.mat", tname);
    evalin('base', saveCommand);
    out = load(tname +".mat");
else
    wBase = matlab.lang.Workspace.baseWorkspace;
    t = variables(wBase);
    for i = 1 : height(t)
        out.(t.Name(i)) = wBase.(t.Name(i));
    end
end
end