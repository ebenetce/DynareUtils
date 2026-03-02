classdef tSubmission < matlab.unittest.TestCase

    methods (Test)
        % Test methods           
        function tSubmitJob(testCase)
            setDynare('6.5')
            c = parcluster('local');
            c.NumThreads = 2;

            fprintf('submitting jobs...')

            dyn = fileparts(which('dynare.m'));
            fcn = @(x) runDynareModel(x, "Flags", ["nolog", "nograph"], DynareLocation = dyn);
            j1 = batch(c, fcn, 2, {which("agtrend.mod")} );

            j2 = batch(c, @runDynareModel, 2, {which("fs2000.mod"), "Flags", ["nograph", "nolog"], ...
                "AttachedFiles", {which("fs2000_nonstationary.mod"), which("fs2000_data.m")}, "DynareLocation", which('dynare.m')});

            cObj1 = onCleanup(@() delete(j1));
            cObj2 = onCleanup(@() delete(j2));
            wait(j1)
            wait(j2)
            testCase.verifyEqual(j1.State, 'finished');
            testCase.verifyEqual(j2.State, 'finished');
            testCase.verifyEmpty(j1.Tasks(1).Error)
            testCase.verifyEmpty(j2.Tasks(1).Error)
        end

    end

end