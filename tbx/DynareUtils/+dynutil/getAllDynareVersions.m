function ver = getAllDynareVersions()

d = extractBetween(webread('https://www.dynare.org/release/windows-7z/'), 'dynare-','-win.7z');
ver = sort(string(d), 1, "descend");

end