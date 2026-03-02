function [available, enabled] = getDynareAddons()
addons = matlab.addons.installedAddons;
available = addons(contains(addons.Identifier, "658a2ffd-f7d5-4170-bcb5-ac75a11196b9", "IgnoreCase",true), :);
if nargout == 2
    enabled = available(available.Enabled == true, :);
end
end