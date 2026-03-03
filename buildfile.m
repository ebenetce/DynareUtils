function plan = buildfile
import matlab.buildtool.tasks.CodeIssuesTask
import matlab.buildtool.tasks.TestTask

% Create a plan from task functions
plan = buildplan(localfunctions);

% Add the "check" task to identify code issues
plan("check") = CodeIssuesTask;

% Add the "test" task to run tests
plan("test") = TestTask(SourceFiles = "tbx", TestResults = "tests/report.html", CodeCoverageResults = 'tests/coverage.html');

% Make the "archive" task the default task in the plan
plan.DefaultTasks = "archive";

plan("doc").Dependencies = "exportmd";

% Make the "archive" task dependent on the "check" and "test" tasks
plan("archive").Dependencies = ["check" "test", "doc"];
end

function exportmdTask(~)

doc = fullfile( dynareUtilsRoot, "dynareutilsdoc" );

export(fullfile(doc, 'mfiles', 'GettingStarted.m'), fullfile(doc, 'index.md'));

% files =  dir(fullfile( dynareUtilsRoot, "DynareUtils", "*.m" ));
% for i = 1 : numel(files)
%     export( fullfile(files(i).folder, files(i).name), fullfile(dynareUtilsRoot, 'doc', strrep(files(i).name, '.m', '.md')) )
% end

end

function docTask(~)

if isempty(ver('docmaker'))
    websave('MATLAB_DocMaker.mltbx','https://github.com/mathworks/docmaker/releases/latest/download/MATLAB_DocMaker.mltbx');
    cobj = onCleanup(@() delete('MATLAB_DocMaker.mltbx'));
    matlab.addons.install('MATLAB_DocMaker.mltbx', true);
end

doc = fullfile( dynareUtilsRoot, "dynareutilsdoc" );

docdelete(doc)

md = fullfile(doc,"**","*.md"); % Markdown documents

html = docconvert(md); % convert to HTML

docrun(html) % run code and insert output
docindex(doc); % index

end 

function archiveTask(~)
here = fileparts(mfilename('fullpath'));

% Create MLTBX
opts = matlab.addons.toolbox.ToolboxOptions('tbx', "9fc9258a-6a2a-476e-8293-6612f961c85d");
opts.AuthorCompany = "MathWorks";
opts.AuthorEmail = "ebenetce@mathworks.com";
opts.AuthorName = "Edu Benet Cerda";
opts.Description = "Several utilities to complement running and managing Dynare models such as Parallel Computing and Version management";
opts.OutputFile = "releases/DynareUtils.mltbx";
opts.Summary = "Dynare utils";
opts.ToolboxGettingStartedGuide = fullfile(here, 'tbx', 'dynareutilsdoc', 'mfiles', 'GettingStarted.m');
opts.ToolboxVersion = ver('DynareUtils').Version;
opts.ToolboxName = "DynareUtils";
opts.SupportedPlatforms.Glnxa64 = false;
opts.SupportedPlatforms.Win64 = true;
opts.SupportedPlatforms.Maci64 = false;
opts.SupportedPlatforms.MatlabOnline = false;
opts.ToolboxMatlabPath = [fullfile(dynareUtilsRoot, "DynareUtils"); fullfile(dynareUtilsRoot,"dynareutilsdoc") ] ;

% Exclude MD files:
opts.ToolboxFiles(endsWith(opts.ToolboxFiles, ".md")) = [];

matlab.addons.toolbox.packageToolbox(opts)

% Add license
lic = fileread( "License.txt" );
mlAddonSetLicense( char( opts.OutputFile ), struct( "type", 'BSD', "text", lic ) );
end