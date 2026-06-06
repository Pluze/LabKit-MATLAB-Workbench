classdef MakeChronoItemTest < matlab.unittest.TestCase
    %MAKECHRONOITEMTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_makeChronoItem(testCase)
            setupLabKitTestPath();
            verify_makeChronoItem();
        end
    end
end

function verify_makeChronoItem()
%TEST_MAKECHRONOITEM Verify chrono item construction through the DTA facade.

    fixture = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');

    [item, status] = labkit.dta.loadFile(fixture, "chrono");
    assert(status.ok, status.message);

    assert(strcmp(item.type, "chrono"), 'Chrono item type should be set.');
    assert(strcmp(item.name, 'chrono_chronopot_current_pulse_0p2ms.DTA'), 'Chrono item name should use the file name.');
    assert(item.controlMode == "current", 'Chrono item should expose current-controlled metadata.');
    assert(numel(item.t_s) == 244 && numel(item.Vf_V) == 244 && numel(item.Im_A) == 244, ...
        'Canonical chrono vectors should be populated.');
    assert(item.n == numel(item.t_s), 'Item sample count should match the canonical time vector.');
    assert(strcmp(item.message, 'Using table: Curve'), 'Main-curve message should preserve stable wording.');
    assert(item.pulse.ok, item.pulseMessage);

    assert(isfield(item, 'alignTime_s') && isnan(item.alignTime_s), ...
        'Reusable chrono item construction should not perform app-specific alignment.');
    assert(isfield(item, 'tAligned_s') && isempty(item.tAligned_s), ...
        'Reusable chrono item construction should leave aligned time for app workflow code.');
end
