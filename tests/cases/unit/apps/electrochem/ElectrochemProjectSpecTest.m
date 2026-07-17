classdef ElectrochemProjectSpecTest < matlab.unittest.TestCase
    %ELECTROCHEMPROJECTSPECTEST Verify App-owned project schema requirements.

    methods (Test)
        function defaultProjectsAcceptAndRequireSources(testCase)
            setupLabKitTestPath();
            factories = {@chrono_overlay.projectSpec, @cic.projectSpec, ...
                @csc.projectSpec, @eis.projectSpec, ...
                @vt_resistance.projectSpec};
            for k = 1:numel(factories)
                spec = factories{k}();
                project = spec.Create();
                testCase.verifyTrue(accepts(spec, project), ...
                    sprintf('Default project %d must be valid.', k));
                project.inputs = rmfield(project.inputs, 'sources');
                testCase.verifyFalse(accepts(spec, project), ...
                    sprintf(['Project %d must declare its App-required ' ...
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
