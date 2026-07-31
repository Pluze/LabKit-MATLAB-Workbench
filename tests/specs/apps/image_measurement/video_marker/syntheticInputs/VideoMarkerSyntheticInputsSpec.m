classdef VideoMarkerSyntheticInputsSpec < matlab.unittest.TestCase
    %VIDEOMARKERSYNTHETICINPUTSSPEC Guard the reproducible sample pack.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function samplePackOwnsAReadableSyntheticVideo(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;

            pack = video_marker.syntheticInputs.writeSamplePack( ...
                labkit.app.synthetic.Context(folder));
            source = pack.InitialProject.inputs.sources;

            testCase.verifyNumElements(source, 1);
            testCase.verifyGreaterThan( ...
                pack.InitialProject.inputs.videoMetadata.frameCount, 0);
            testCase.verifyGreaterThan( ...
                pack.InitialProject.parameters.coordinateEndFrame, 0);
        end
    end
end
