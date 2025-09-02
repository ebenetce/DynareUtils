function [available, enabled] = getDynareAddons()
addons = matlab.addons.installedAddons;
available = addons(contains(addons.Identifier, "dynare", "IgnoreCase",true), :);
if nargout == 2
    enabled = available(available.Enabled == true, :);
end
end