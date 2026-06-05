classdef BiosignalRecordingImportTest < matlab.unittest.TestCase
    %BIOSIGNALRECORDINGIMPORTTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_biosignalRecordingImport(testCase)
            setupLabKitTestPath();
            verify_biosignalRecordingImport();
        end
    end
end

function verify_biosignalRecordingImport()
%TEST_BIOSIGNALRECORDINGIMPORT Verify MAT/timetable import and channel access.

    tempFile = [tempname(tempdir) '.mat'];
    cleaner = onCleanup(@() cleanupFile(tempFile)); %#ok<NASGU>

    fs = 100;
    t = (0:1/fs:10).';
    x = syntheticEcgValues(t);
    TT = timetable(seconds(t), x, 'VariableNames', {'ECG'}); %#ok<NASGU>
    save(tempFile, 'TT');

    [recording, status] = labkit.biosignal.readRecording(tempFile);
    assert(status.ok, status.message);
    channels = labkit.biosignal.listChannels(recording);
    assert(numel(channels) == 1, 'Expected one numeric timetable channel.');

    sig = labkit.biosignal.getChannel(recording, channels{1});
    assert(abs(sig.fs - fs) < 1e-9, 'Sample rate should be inferred from timetable row times.');

    cropped = labkit.biosignal.cropSignal(sig, [0.5 9.5]);
    assert(cropped.time(1) == 0, 'Cropped signal time should restart at zero.');
    assert(numel(cropped.values) < numel(sig.values), 'Cropped signal should contain fewer samples.');
end

function x = syntheticEcgValues(t)
    x = 0.03 * sin(2*pi*1.5*t);
    for peakTime = 1:9
        x = x + exp(-((t - peakTime) / 0.025).^2);
    end
    x = x + 0.01 * sin(2*pi*17*t);
end

function cleanupFile(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end
