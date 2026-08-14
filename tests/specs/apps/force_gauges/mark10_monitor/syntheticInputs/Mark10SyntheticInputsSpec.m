classdef Mark10SyntheticInputsSpec < matlab.unittest.TestCase
    %MARK10SYNTHETICINPUTSSPEC Specify anonymous replay sample generation.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function writesReopenableCsvLogAndMatArtifacts(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            pack = mark10_monitor.syntheticInputs.writeSamplePack( ...
                labkit.app.synthetic.Context(folder));

            testCase.verifyEqual(pack.Scenario, ...
                "representative-force-travel-replay");
            testCase.verifyNumElements(pack.Artifacts, 3);
            for artifact = pack.Artifacts
                filepath = fullfile(folder, artifact{1}.RelativePath);
                testCase.verifyTrue(isfile(filepath));
                data = mark10_monitor.playback.readRecording(filepath);
                testCase.verifyGreaterThan(numel(data.Time_s), 20);
            end
        end
    end
end
