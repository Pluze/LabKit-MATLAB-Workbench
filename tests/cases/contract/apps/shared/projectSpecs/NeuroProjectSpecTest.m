classdef NeuroProjectSpecTest < matlab.unittest.TestCase
    %NEUROPROJECTSPECTEST Verify neurophysiology project requirements.

    methods (Test, TestTags = {'Unit'})
        function defaultProjectsAcceptAndRequireSources(testCase)
            setupLabKitTestPath();
            factories = {@nerve_response_analysis.projectSpec, ...
                @response_review_stats.projectSpec, @rhs_preview.projectSpec};
            for k = 1:numel(factories)
                spec = factories{k}();
                project = spec.Create();
                testCase.verifyTrue(accepts(spec, project), ...
                    sprintf('Default neuro project %d must be valid.', k));
                project.inputs = rmfield(project.inputs, 'sources');
                testCase.verifyFalse(accepts(spec, project), ...
                    sprintf(['Neuro project %d must declare its App-required ' ...
                    'source collection.'], k));
            end
        end

        function appSpecificSourceRolesRemainValidated(testCase)
            setupLabKitTestPath();
            source = labkit.app.project.sourceRecord( ...
                "unexpected", "unexpected", "synthetic.dat", false);

            nerveSpec = nerve_response_analysis.projectSpec();
            nerveProject = nerveSpec.Create();
            nerveProject.inputs.sources = source;
            testCase.verifyFalse(accepts(nerveSpec, nerveProject));

            rhsSpec = rhs_preview.projectSpec();
            rhsProject = rhsSpec.Create();
            rhsProject.inputs.sources = source;
            testCase.verifyFalse(accepts(rhsSpec, rhsProject));
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
