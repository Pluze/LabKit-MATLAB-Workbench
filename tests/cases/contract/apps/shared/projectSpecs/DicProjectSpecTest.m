classdef DicProjectSpecTest < matlab.unittest.TestCase
    %DICPROJECTSPECTEST Verify DIC App-owned project schema requirements.

    methods (Test, TestTags = {'Unit'})
        function defaultProjectsAcceptAndRequireSources(testCase)
            setupLabKitTestPath();
            factories = {@dic_postprocess.projectSpec, ...
                @dic_preprocess.projectSpec};
            for k = 1:numel(factories)
                spec = factories{k}();
                project = spec.Create();
                testCase.verifyTrue(accepts(spec, project), ...
                    sprintf('Default DIC project %d must be valid.', k));
                project.inputs = rmfield(project.inputs, 'sources');
                testCase.verifyFalse(accepts(spec, project), ...
                    sprintf(['DIC project %d must declare its App-required ' ...
                    'source collection.'], k));
            end
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
