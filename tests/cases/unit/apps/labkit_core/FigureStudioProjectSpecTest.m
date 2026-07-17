classdef FigureStudioProjectSpecTest < matlab.unittest.TestCase
    %FIGURESTUDIOPROJECTSPECTEST Verify Figure Studio project requirements.

    methods (Test)
        function defaultProjectAcceptsAndRequiresSources(testCase)
            setupLabKitTestPath();
            spec = figure_studio.projectSpec();
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
