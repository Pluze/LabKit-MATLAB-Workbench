classdef ImageProjectSpecTest < matlab.unittest.TestCase
    %IMAGEPROJECTSPECTEST Verify image App-owned project schema requirements.

    methods (Test, TestTags = {'Unit'})
        function defaultProjectsAcceptAndRequireSources(testCase)
            setupLabKitTestPath();
            factories = {@batch_crop.projectSpec, @curvature.projectSpec, ...
                @flir_thermal.projectSpec, @focus_stack.projectSpec, ...
                @image_enhance.projectSpec, @image_match.projectSpec, ...
                @video_marker.projectSpec};
            for k = 1:numel(factories)
                spec = factories{k}();
                project = spec.Create();
                testCase.verifyTrue(accepts(spec, project), ...
                    sprintf('Default image project %d must be valid.', k));
                project.inputs = rmfield(project.inputs, 'sources');
                testCase.verifyFalse(accepts(spec, project), ...
                    sprintf(['Image project %d must declare its App-required ' ...
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
