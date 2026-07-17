classdef EcgProjectSpecTest < matlab.unittest.TestCase
    %ECGPROJECTSPECTEST Verify ECG Print project requirements.

    methods (Test, TestTags = {'Unit'})
        function defaultProjectAcceptsAndRequiresSources(testCase)
            setupLabKitTestPath();
            spec = ecg_print.projectSpec();
            project = spec.Create();
            testCase.verifyTrue(accepts(spec, project));
            project.inputs = rmfield(project.inputs, 'sources');
            testCase.verifyFalse(accepts(spec, project));
        end
    end
end

function accepted = accepts(spec, project)
    try
        accepted = spec.Validate(project);
        accepted = islogical(accepted) && isscalar(accepted) && accepted;
    catch
        accepted = false;
    end
end
