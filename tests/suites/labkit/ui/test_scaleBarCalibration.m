function test_scaleBarCalibration()
%TEST_SCALEBARCALIBRATION Verify reusable scale-bar calibration model.

    checkTypedCalibration();
    checkReferenceLineCalibration();
    checkFallbackUnitAndMissingScale();
end

function checkTypedCalibration()
    cal = labkit.ui.scaleBarCalibration(80, 20, "mm");
    assert(cal.isCalibrated, 'Positive reference pixels and length should calibrate.');
    assert(cal.pixelsPerUnit == 4, 'Pixels per unit calculation changed.');
    assert(strcmp(cal.unit, 'mm'), 'Selected scale unit should be preserved.');
    assert(cal.referencePixels == 80 && cal.referenceLength == 20, ...
        'Reference calibration fields changed.');
end

function checkReferenceLineCalibration()
    cal = labkit.ui.scaleBarCalibration(NaN, 2, "cm", ...
        struct('referenceLine', [0 0; 3 4]));
    assert(cal.isCalibrated, 'Two reference endpoints should provide reference pixels.');
    assert(cal.referencePixels == 5, 'Reference line pixel distance changed.');
    assert(cal.pixelsPerUnit == 2.5, 'Reference line pixels/unit calculation changed.');
    assert(isequal(cal.referenceLine, [0 0; 3 4]), ...
        'Reference line endpoints should be preserved.');
end

function checkFallbackUnitAndMissingScale()
    cal = labkit.ui.scaleBarCalibration(NaN, 0, "inch");
    assert(~cal.isCalibrated, 'Missing reference scale should remain uncalibrated.');
    assert(cal.pixelsPerUnit == 0, 'Missing reference scale should produce zero pixels/unit.');
    assert(strcmp(cal.unit, 'm'), 'Unsupported units should fall back to the default unit.');
end
