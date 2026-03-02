classdef tManageDynare < matlab.unittest.TestCase
    
    methods (Test)
        function tSetDynare(tc)            
            setDynare('5.5')
            tc.verifyEqual(dynare_version, '5.5')
            disableDynare()
            tc.verifyEmpty(which('dynare_version'))            
            setDynare('4.6.3')
            tc.verifyEqual(dynare_version, '4.6.3')
            uninstallDynare('4.6.3')
            tc.verifyEmpty(which('dynare_version'))
            setDynare()
            tc.verifyEqual(dynare_version, '6.5')
        end
    end
end