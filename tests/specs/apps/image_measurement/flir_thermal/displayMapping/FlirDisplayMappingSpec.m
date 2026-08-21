classdef FlirDisplayMappingSpec < matlab.unittest.TestCase
    %FLIRDISPLAYMAPPINGSPEC Guard shared thermal display ranges.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function sharedRangeStoresOneAnnotationPerSource(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = testfixtures.flir_thermal.project(string(folder));
            definition = flir_thermal.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createHeadlessRuntime( ...
                definition, project, struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("groupRange");
            state = runtime.State;
            annotations = state.project.annotations.items;

            testCase.verifyNumElements(annotations, ...
                numel(state.project.inputs.sources));
            ranges = vertcat(annotations.displayRange);
            testCase.verifyEqual(ranges, ...
                repmat(ranges(1, :), size(ranges, 1), 1));
            clear cleanup
        end
    end
end
