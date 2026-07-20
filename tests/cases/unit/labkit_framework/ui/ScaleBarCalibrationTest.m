classdef ScaleBarCalibrationTest < matlab.unittest.TestCase
    %SCALEBARCALIBRATIONTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_scaleBarCalibration(testCase)
            setupLabKitTestPath();
            verify_scaleBarCalibration();
        end
    end
end

function verify_scaleBarCalibration()
%TEST_SCALEBARCALIBRATION Verify reusable scale-bar calibration model.

    checkTypedCalibration();
    checkReferenceLineCalibration();
    checkFallbackUnitAndMissingScale();
end

function checkTypedCalibration()
    cal = labkit.app.interaction.scaleCalibration(80, 20, "mm");
    assert(cal.isCalibrated, 'Positive reference pixels and length should calibrate.');
    assert(cal.pixelsPerUnit == 4, 'Pixels per unit calculation changed.');
    assert(strcmp(cal.unit, 'mm'), 'Selected scale unit should be preserved.');
    assert(cal.referencePixels == 80 && cal.referenceLength == 20, ...
        'Reference calibration fields changed.');
end

function checkReferenceLineCalibration()
    cal = labkit.app.interaction.scaleCalibration(NaN, 2, "cm", ...
        struct('referenceLine', [0 0; 3 4]));
    assert(cal.isCalibrated, 'Two reference endpoints should provide reference pixels.');
    assert(cal.referencePixels == 5, 'Reference line pixel distance changed.');
    assert(cal.pixelsPerUnit == 2.5, 'Reference line pixels/unit calculation changed.');
    assert(isequal(cal.referenceLine, [0 0; 3 4]), ...
        'Reference line endpoints should be preserved.');
end

function checkFallbackUnitAndMissingScale()
    cal = labkit.app.interaction.scaleCalibration(NaN, 0, "inch");
    assert(~cal.isCalibrated, 'Missing reference scale should remain uncalibrated.');
    assert(cal.pixelsPerUnit == 0, 'Missing reference scale should produce zero pixels/unit.');
    assert(strcmp(cal.unit, 'm'), 'Unsupported units should fall back to the default unit.');
end
