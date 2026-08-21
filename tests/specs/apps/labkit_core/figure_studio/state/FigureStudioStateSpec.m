classdef FigureStudioStateSpec < matlab.unittest.TestCase
    %FIGURESTUDIOSTATESPEC Specify current Figure Studio state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsACompleteValidStyleState(testCase)
            project = figure_studio.initialData();
            testCase.verifyTrue(isfield(project.parameters.style, ...
                "referenceCanvasWidth"));
            testCase.verifyTrue(isfield(project.annotations, "panelIndex"));
        end
    end
end
