classdef ChronoOverlayStateSpec < matlab.unittest.TestCase
    %CHRONOOVERLAYSTATESPEC Specify current Chrono Overlay state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function validatesCurrentDefaultsAndDefinitionMetadata(testCase)
            definition = chrono_overlay.definition();
            project = chrono_overlay.initialData();
            version = labkit_ChronoOverlay_app("version");

            testCase.verifyTrue(isfinite(project.parameters.lineWidth));
            testCase.verifyEqual(string(version.version), definition.AppVersion);
        end
    end
end
