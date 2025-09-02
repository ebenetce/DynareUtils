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

% Make the "archive" task dependent on the "check" and "test" tasks
plan("archive").Dependencies = ["check" "test"];
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
opts.ToolboxGettingStartedGuide = fullfile(here, 'tbx', 'doc', 'GettingStarted.mlx');
opts.ToolboxVersion = '0.1.0';
opts.ToolboxName = "DynareUtils";
opts.SupportedPlatforms.Glnxa64 = false;
opts.SupportedPlatforms.Win64 = true;
opts.SupportedPlatforms.Maci64 = false;
opts.SupportedPlatforms.MatlabOnline = false;
opts.ToolboxMatlabPath = fullfile(here, 'tbx','DynareUtils');
          
matlab.addons.toolbox.packageToolbox(opts)
end