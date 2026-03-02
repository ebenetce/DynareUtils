classdef tOptim < matlab.unittest.TestCase

    methods (TestClassSetup)
        function startParallelEnv(~)
            setDynare('6.5')
            if isempty(gcp("nocreate"))
                parpool('Processes');
            end
        end
    end

    methods (TestClassTeardown)
        function closeFigures(~)
            close all
            delete(gcp("nocreate"))
        end
    end

    methods (Test)
        function tFmincon(testCase)
            out = dynareParallel(which('fmincon_parallel.mod'), 'AdditionalFiles', which('usmodel_data.mat'), Flags = ["nograph", "nolog", "-DParallel=true"]);

            out2 = dynareParallel(which('fmincon_parallel.mod'), 'AdditionalFiles', which('usmodel_data.mat'), Flags = ["nograph", "nolog", "-DParallel=false"], UseParallel = false);

            testCase.verifyEqual(out.oo_.posterior.optimization.log_density, out2.oo_.posterior.optimization.log_density, RelTol = 1e-9)
            testCase.verifyEqual(out.oo_.MarginalDensity.LaplaceApproximation,out2.oo_.MarginalDensity.LaplaceApproximation, RelTol = 1e-7)
        end
    end
end