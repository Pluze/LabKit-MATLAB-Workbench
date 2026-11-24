classdef EmgReviewWorkflowSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:workflow','Env:hidden-gui'})
        function opensAcqAndMeasuresAutomaticAndManualPairs(testCase)
            testCase.assertEqual(string(getenv('LABKIT_GUI_TEST_MODE')), "hidden");
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            fs = 2000;
            % Integer wave blocks yield exactly 1:4 RMS and 2:3 RMS ratios.
            phase = repmat([-1;1], fs/2, 1);
            raw = phase .* [2 8 4 6];
            source = testfixtures.biosignal.writeAcq(folder, raw(:));
            definition = emg_review.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime(definition, [], ...
                struct("alert", @(~,~) []), journal);
            cleanup = onCleanup(@() runtime.close());
            testCase.assertFalse(runtime.StartupFailed);
            figureValue = runtime.figureHandle();
            testCase.assertEqual(string(figureValue.Visible), "off");

            runtime.applyFileSelection("recording", source, 1);
            testCase.verifyEqual(runtime.State.session.signal.fs, fs);
            testCase.verifyEqual(runtime.State.session.band, "As recorded");
            runtime.invokeAction("autoMark");
            testCase.verifyEqual(runtime.State.session.pairs, [0 1]);
            runtime.invokeAction("addPair");
            runtime.applyControlValue("baselineStart", 2);
            runtime.applyControlValue("activityStart", 3);
            runtime.invokeAction("analyze");
            result = runtime.State.session.result;
            testCase.assertNotEmpty(result, runtime.State.session.analysisStatus);
            testCase.verifyEqual(result.metrics.SNR_dB, 10*log10([15;1.25]), AbsTol=1e-12);

            overview = findall(figureValue, 'Tag', 'waveform.main');
            labels = string({findall(overview, 'Type', 'text').String});
            testCase.verifyTrue(any(labels == "Baseline 2"));
            testCase.verifyTrue(any(startsWith(labels, "Activity 2 · 1.0 dB")));
            plotSpectrum = findall(figureValue, 'Tag', 'spectrum.main');
            testCase.verifyEqual(numel(findall(plotSpectrum, 'Type', 'line')), 2);
            spectrogram = findall(figureValue, 'Tag', 'timeFrequency.main');
            testCase.verifyNotEmpty(findall(spectrogram, 'Type', 'image'));
            testCase.verifyEqual(plotSpectrum.XLim, [5 500]);
            testCase.verifyEqual(spectrogram.YLim, [5 500]);

            runtime.applyControlValue("pair", "1");
            testCase.verifyEqual(runtime.State.session.pairIndex, 1);
            testCase.verifyNotEmpty(runtime.State.session.result);
            runtime.invokeAction("removePair");
            testCase.verifyEqual(runtime.State.session.pairs, [2 3]);
            testCase.verifyEmpty(runtime.State.session.result);
        end
    end
end
