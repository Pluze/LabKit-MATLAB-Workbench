classdef WearableDebugSamplePackTest < matlab.unittest.TestCase
    %WEARABLEDEBUGSAMPLEPACKTEST Verify wearable debug sample packs.

    methods (Test, TestTags = {'Unit'})
        function ecg_debug_sample_pack_reads_through_biosignal_facade(testCase)
            setupLabKitTestPath();
            root = string(tempname);
            cleanup = onCleanup(@() cleanupFolder(root));
            mkdir(char(root));
            debug = labkit.ui.debug.context("wearable_debug_sample_test", struct( ...
                "logFile", fullfile(char(root), "trace.log")));

            pack = ecg_print.debug.writeSamplePack(debug);
            [recording, status] = labkit.biosignal.readRecording(char(pack.representativeFiles), ...
                ecg_print.sourceFiles.importOptions(500, 1, "Yes", "time_s", "seconds", "ECG,Motion"));
            testCase.verifyTrue(status.ok, status.message);
            channels = labkit.biosignal.listChannels(recording);
            testCase.verifyTrue(any(strcmp(channels, "ECG")));
            signal = labkit.biosignal.getChannel(recording, "ECG");
            testCase.verifyGreaterThan(numel(signal.time), 1000);

            [headerless, headerlessStatus] = labkit.biosignal.readRecording( ...
                char(pack.boundaryFiles.validHeaderlessText), ...
                ecg_print.sourceFiles.importOptions(500, 1, "No", "1", "seconds", "2,3"));
            testCase.verifyTrue(headerlessStatus.ok);
            testCase.verifyGreaterThan(numel(labkit.biosignal.listChannels(headerless)), 0);

            [~, malformedStatus] = labkit.biosignal.readRecording( ...
                char(pack.boundaryFiles.malformedCsv), ...
                ecg_print.sourceFiles.importOptions(500, 1, "Yes", "time_s", "seconds", "ECG"));
            testCase.verifyFalse(malformedStatus.ok, ...
                "Malformed ECG debug sample should fail cleanly through the biosignal facade.");
        end
    end
end

function cleanupFolder(folder)
    if strlength(string(folder)) > 0 && exist(char(folder), "dir") == 7
        rmdir(char(folder), "s");
    end
end
