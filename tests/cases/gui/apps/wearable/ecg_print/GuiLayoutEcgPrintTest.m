classdef GuiLayoutEcgPrintTest < matlab.unittest.TestCase
    %GUILAYOUTECGPRINTTEST Verify ECG Print GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function ecg_print_workflow_loads_analyzes_and_plots_recording(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            recordingPath = fullfile(folder, 'synthetic_ecg.csv');
            writeSyntheticEcgCsv(recordingPath);

            fig = h.launchFigure('labkit_ECGPrint_app', ...
                'ECG Signal Print + SNR Explorer');
            assertEcgPrintLayout(h, fig);
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('recording', recordingPath);

            driver.click('Open recording');
            driver.dropdown('Local peaks');
            driver.click('Analyze current ROI');

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.recording.status.Value), ...
                'synthetic_ecg.csv'), ...
                'ECG Print workflow should show the loaded recording path.');
            importStatus = string(ui.controls.importStatus.valueHandle.Value);
            testCase.verifyFalse(contains(importStatus, 'Parse failed'), ...
                'ECG Print workflow should parse the synthetic recording.');
            testCase.verifyFalse(contains(importStatus, 'Open a recording'), ...
                'ECG Print workflow should leave the empty import state after loading.');
            testCase.verifyTrue(any(strcmp(ui.controls.channel.valueHandle.Items, 'ECG')), ...
                'ECG Print workflow should populate the ECG channel choice.');

            data = driver.tableData('summaryTable');
            metricNames = string(data(:, 1));
            testCase.verifyTrue(any(metricNames == "Detected peaks"), ...
                'ECG Print workflow should report detected peaks after analysis.');
            testCase.verifyTrue(any(metricNames == "Mean SNR (dB)"), ...
                'ECG Print workflow should report SNR summary after analysis.');
            testCase.verifyGreaterThan(numel(ui.controls.previewAxes.axesById.wave.Children), 0, ...
                'ECG Print workflow should draw the waveform plot.');
            testCase.verifyGreaterThan(numel(ui.controls.previewAxes.axesById.noise.Children), 0, ...
                'ECG Print workflow should draw the noise plot.');
            testCase.verifyGreaterThan(numel(ui.controls.previewAxes.axesById.snr.Children), 0, ...
                'ECG Print workflow should draw the SNR plot.');
            testCase.verifyGreaterThan(numel(ui.controls.previewAxes.axesById.template.Children), 0, ...
                'ECG Print workflow should draw the template plot.');
        end
    end
end

function assertEcgPrintLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Open recording', 'Analyze current ROI', ...
        'Preview file header', 'Parse / refresh file', ...
        'Export segment SNR CSV', 'Export waveform PNG'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'Auto', 'Yes', 'No'}, 1), ...
        h.dropdownGroup({'Auto', 'seconds', 'milliseconds', ...
        'microseconds', 'nanoseconds'}, 1), ...
        h.dropdownGroup({'(none)'}, 1), ...
        h.dropdownGroup({'QRS streaming', 'Pan-Tompkins', 'Local peaks'}, 1), ...
        h.dropdownGroup({'Template + residual band', 'Template + segments'}, 1)]);
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
end

function writeSyntheticEcgCsv(filepath)
    fs = 500;
    durationSec = 4;
    time = (0:(durationSec * fs - 1)).' ./ fs;
    ecg = 0.05 .* sin(2 .* pi .* 1.7 .* time) + ...
        0.02 .* sin(2 .* pi .* 23 .* time);
    for peakTime = 1:durationSec - 1
        ecg = ecg + 1.8 .* exp(-((time - peakTime) ./ 0.018).^2);
        ecg = ecg - 0.25 .* exp(-((time - peakTime - 0.045) ./ 0.026).^2);
    end
    T = table(time, ecg, 'VariableNames', {'time_s', 'ECG'});
    writetable(T, filepath);
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
