classdef ImageEnhanceSourceSpec < matlab.unittest.TestCase
    %IMAGEENHANCESOURCESPEC Specify image import and progress evidence.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function loadsFilePanelPathsAndReportsEveryReadStage(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            first = fullfile(folder, "first.png");
            second = fullfile(folder, "second.png");
            imwrite(uint8(80 .* ones(8, 9, 3)), first);
            imwrite(uint8(120 .* ones(7, 6, 3)), second);
            events = {};

            items = image_enhance.sourceFiles.readImages([string(first); string(second)], ...
                struct("progressFcn", @capture));

            testCase.verifyEqual(numel(items), 2);
            testCase.verifyEqual(string(cellfun(@(event) event.stage, events, ...
                UniformOutput=false)), ["beforeRead"; "afterRead"; "beforeRead"; "afterRead"]);

            function capture(event)
                events{end + 1, 1} = event;
            end
        end
    end
end
