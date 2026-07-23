classdef ChronoOverlaySourceSpec < matlab.unittest.TestCase
    %CHRONOOVERLAYSOURCESPEC Specify pulse-gap alignment of source traces.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function alignsAtTheDetectedBlankGapCenter(testCase)
            item = ChronoOverlaySourceSpec.item((0:0.1:0.8).', ...
                struct("ok", true, "gap_start", 0.3, "gap_end", 0.5, ...
                "method", "synthetic"));

            [aligned, message] = chrono_overlay.sourceFiles.alignByPulseGap(item);

            testCase.verifyEqual(aligned.alignTime_s, 0.4, "AbsTol", 1e-12);
            testCase.verifyEqual(aligned.tAligned_s, item.t_s - 0.4, "AbsTol", 1e-12);
            testCase.verifySubstring(string(message), "blank center");
        end

        function fallsBackToTheFirstSampleWhenNoPulseExists(testCase)
            item = ChronoOverlaySourceSpec.item((2:4).', ...
                struct("ok", false, "message", "synthetic pulse not found"));

            [aligned, message] = chrono_overlay.sourceFiles.alignByPulseGap(item);

            testCase.verifyEqual(aligned.alignTime_s, 2, "AbsTol", 1e-12);
            testCase.verifyEqual(aligned.tAligned_s, [0; 1; 2], "AbsTol", 1e-12);
            testCase.verifySubstring(string(message), "fallback to first sample");
        end
    end

    methods (Static, Access = private)
        function item = item(time, pulse)
            item = struct("name", "synthetic chrono", "t_s", time, ...
                "Vf_V", zeros(size(time)), "Im_A", zeros(size(time)), ...
                "pulse", pulse);
        end
    end
end
