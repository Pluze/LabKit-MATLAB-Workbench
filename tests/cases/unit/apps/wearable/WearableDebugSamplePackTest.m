classdef WearableDebugSamplePackTest < matlab.unittest.TestCase
    %WEARABLEDEBUGSAMPLEPACKTEST Verify wearable debug sample packs.

    methods (Test, TestTags = {'Unit'})
        function ecg_debug_sample_pack_reads_through_biosignal_facade(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(root));
            context = labkit.app.diagnostic.SampleContext(root);

            pack = ecg_print.debug.writeSamplePack(context);
            testCase.verifyClass(pack, "labkit.app.diagnostic.SamplePack");
            testCase.verifyEqual(string( ...
                pack.InitialProject.inputs.sources.role), "recording");
            [recording, status] = labkit.biosignal.readRecording( ...
                artifactPath(context, pack, "recording"), ...
                ecg_print.sourceFiles.importOptions(500, 1, "Yes", "time_s", "seconds", "ECG,Motion"));
            testCase.verifyTrue(status.ok, status.message);
            channels = labkit.biosignal.listChannels(recording);
            testCase.verifyTrue(any(strcmp(channels, "ECG")));
            signal = labkit.biosignal.getChannel(recording, "ECG");
            testCase.verifyGreaterThan(numel(signal.time), 1000);

            [headerless, headerlessStatus] = labkit.biosignal.readRecording( ...
                artifactPath(context, pack, "headerless"), ...
                ecg_print.sourceFiles.importOptions(500, 1, "No", "1", "seconds", "2,3"));
            testCase.verifyTrue(headerlessStatus.ok);
            testCase.verifyGreaterThan(numel(labkit.biosignal.listChannels(headerless)), 0);

            [~, malformedStatus] = labkit.biosignal.readRecording( ...
                artifactPath(context, pack, "malformed"), ...
                ecg_print.sourceFiles.importOptions(500, 1, "Yes", "time_s", "seconds", "ECG"));
            testCase.verifyFalse(malformedStatus.ok, ...
                "Malformed ECG debug sample should fail cleanly through the biosignal facade.");
        end
    end
end

function filepath = artifactPath(context, pack, id)
matches = cellfun(@(artifact) artifact.Id == id, pack.Artifacts);
filepath = char(fullfile(context.ArtifactFolder, ...
    pack.Artifacts{matches}.RelativePath));
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end
