function ver = getAllDynareVersions()

d = extractBetween(webread('https://www.dynare.org/release/windows-zip/'), 'dynare-','-win.zip');
ver = sort(string(d), 1, "descend");

end