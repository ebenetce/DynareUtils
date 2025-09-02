classdef tRunDynare < matlab.unittest.TestCase

    methods (TestClassSetup)
        function startParallelEnv(~)
            setDynare('6.3')
            c = parcluster('local');
            c.NumThreads = 2;
            if isempty(gcp("nocreate"))
                parpool(c, 2)
            end            
        end
    end

    methods (TestClassTeardown)
        function closeFigures(~)
            close all
            delete(gcp("nocreate"))
        end
    end

    methods (TestMethodSetup)
        % Setup for each test
    end

    methods (Test)
        % Test methods
        function tBasicTest(testCase)
            out = dynareParallel(which('agtrend.mod'), Flags = ["nowarn", "nolog", "nograph"]);
            testCase.verifyClass(out, 'struct')
        end

        

        function tSerialFs2000(testCase)           

            out = dynareParallel(which('fs2000.mod'), AdditionalFiles = which("fs2000_data.m"), Flags = ["nograph", "nolog"]);
            testCase.verifyClass(out, 'struct')

            out2 = dynareParallel(which('fs2000.mod'), AdditionalFiles = which("fs2000_data.m"), Flags = ["nograph", "nolog"], UseParallel = false);

            % remove timing fields, these won't match
            out = rmfield(out, 'tic0');
            out2 = rmfield(out2, 'tic0');
            out.oo_ = rmfield(out.oo_, 'time');
            out2.oo_ = rmfield(out2.oo_, 'time');

            % Start comparison
            flds1 = fields(out);
            flds2 = fields(out2);
            testCase.verifyEqual(flds1, flds2)

            
            for i = 1 : numel(flds1)
                testCase.verifyEqual(out.(flds1{i}), out2.(flds1{i}))
            end

        end
    end

end