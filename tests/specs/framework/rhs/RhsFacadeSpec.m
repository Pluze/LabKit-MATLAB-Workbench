classdef RhsFacadeSpec < matlab.unittest.TestCase
    %RHSFACADESPEC Specify public Intan RHS discovery and read behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function discoversAndIndexesSyntheticRhsInputs(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            primary = fullfile(folder, "primary.rhs");
            nested = fullfile(folder, "nested", "secondary.rhs");
            mkdir(fileparts(nested));
            writeSyntheticRhsFixture(primary, struct("nBlocks", 2));
            writeSyntheticRhsFixture(nested, struct("nBlocks", 1));

            files = labkit.rhs.findFiles(folder);
            [info, status] = labkit.rhs.inspectFile(primary);
            [index, indexStatus] = labkit.rhs.indexFile(primary);

            testCase.verifyEqual(sort(string(files)), sort([string(primary); string(nested)]));
            testCase.verifyTrue(status.ok, status.message);
            testCase.verifyEqual(info.fileVersion, [3, 4]);
            testCase.verifyEqual(info.sampleRateHz, 30000);
            testCase.verifyEqual(info.sampleCount, 256);
            testCase.verifyEqual(string(info.channelTable.nativeName(1)), "C-001");
            testCase.verifyTrue(indexStatus.ok, indexStatus.message);
            testCase.verifyEqual([index.blockCount, index.sampleCount], [2, 256]);
        end

        function readsNamedRhsWaveformWindowsInPhysicalUnits(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            source = fullfile(folder, "recording.rhs");
            writeSyntheticRhsFixture(source, struct("nBlocks", 2, ...
                "stimPulseSamples", [1, 2, 3]));

            [amplifier, status] = labkit.rhs.readWindow(source, struct( ...
                "family", "amplifier", "channels", "C001", ...
                "timeRangeSec", [0, 3 / 30000]));
            [stimulation, stimulationStatus] = labkit.rhs.readWindow(source, struct( ...
                "family", "stim", "channels", "C-001", ...
                "timeRangeSec", [0, 3 / 30000]));

            testCase.verifyTrue(status.ok, status.message);
            testCase.verifyEqual(amplifier.family, "amplifier");
            testCase.verifyEqual(amplifier.unit, "microvolts");
            testCase.verifyEqual(amplifier.channels, "C-001");
            testCase.verifyEqual(amplifier.values(:).', 0.195 .* (100:103), ...
                "AbsTol", 1e-12);
            testCase.verifyTrue(stimulationStatus.ok, stimulationStatus.message);
            testCase.verifyEqual(stimulation.family, "stim");
            testCase.verifyEqual(stimulation.unit, "microamps");
            testCase.verifySize(stimulation.values, [4, 1]);
            testCase.verifyGreaterThan(sum(abs(stimulation.values)), 0);
        end
    end
end
