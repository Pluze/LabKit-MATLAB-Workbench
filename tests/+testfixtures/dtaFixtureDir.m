function folder = dtaFixtureDir()
%DTAFIXTUREDIR Create and return a cross-owner synthetic DTA fixture directory.

    names = [
        "chrono_chronopot_current_pulse_0p2ms.DTA"
        "chrono_chronopot_current_pulse_1ms.DTA"
        "chrono_chronopot_current_pt_0p65ms.DTA"
        "chrono_chronoamp_voltage_pulse_0p2ms.DTA"
        "chrono_chronoamp_voltage_pulse_1ms.DTA"
        "cv_cyclic_voltammetry_pt_reference.DTA"
        "cv_cyclic_voltammetry_pt_replicate.DTA"
        "eis_potentiostatic_zcurve.DTA"
        ];

    for k = 1:numel(names)
        testfixtures.dtaFixturePath(names(k));
    end

    folder = fileparts(testfixtures.dtaFixturePath(names(1)));
end
