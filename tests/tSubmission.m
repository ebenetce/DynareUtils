classdef tSubmission < matlab.unittest.TestCase

    methods (Test)
        % Test methods           
        function tSubmitJob(testCase)
            setDynare('6.3')
            c = parcluster('local');
            c.NumThreads = 2;

            fprintf('submitting jobs...')

            fcn = @(x) runDynareModel(x, "Flags", ["nolog", "nograph"]);
            j1 = batch(c, fcn, 2, {which("agtrend.mod")} );

            j2 = batch(c, @runDynareModel, {which("fs2000.mod"), "DynareFlags", ["nograph", "nolog"], ...
                "AttachedFiles", {which("fs2000_nonstationary.mod"), which("fs2000_data.m")}});
            
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