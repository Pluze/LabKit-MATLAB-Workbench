classdef NeurophysiologyWorkflowLayoutTest < matlab.unittest.TestCase
    %NEUROPHYSIOLOGYWORKFLOWLAYOUTTEST Verify RHS app-family workflow layouts.

    methods (Test, TestTags = {'Unit'})
        function previewOwnsProtocolDraftingSurface(testCase)
            setupLabKitTestPath();
            definition = rhs_preview.definition();

            expected = ["previewChannelsTable", "fileFilterTable", ...
                "saveProtocol", "saveFilterRecord", "zoomToRoiWindow"];
            testCase.verifyTrue(all(ismember(expected, ...
                labkit.app.internal.DefinitionInspector.targetIds( ...
                    definition))));
        end

        function analysisWorkflowKeepsHeavyAnalyzeExplicit(testCase)
            setupLabKitTestPath();
            definition = nerve_response_analysis.definition();

            expected = ["sessionFile", "protocolFile", ...
                "runAnalysis", "exportAnalysis"];
            testCase.verifyTrue(all(ismember(expected, ...
                labkit.app.internal.DefinitionInspector.targetIds( ...
                    definition))));
        end

        function statsWorkflowAutoLoadHasRefreshAndExport(testCase)
            setupLabKitTestPath();
            definition = response_review_stats.definition();

            expected = ["loadMetrics", "exportMetrics"];
            testCase.verifyTrue(all(ismember(expected, ...
                labkit.app.internal.DefinitionInspector.targetIds( ...
                    definition))));
        end
    end
end
