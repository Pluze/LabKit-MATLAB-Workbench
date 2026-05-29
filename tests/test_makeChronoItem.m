function test_makeChronoItem()
%TEST_MAKECHRONOITEM Verify reusable chrono item construction.

    root = fileparts(fileparts(mfilename('fullpath')));
    fixture = fullfile(root, 'demo', 'chrono_chronopot_current_pulse_0p2ms.DTA');

    item = gamrywb.data.makeChronoItem(fixture);

    assert(strcmp(item.type, "chrono"), 'Chrono item type should be set.');
    assert(strcmp(item.name, 'chrono_chronopot_current_pulse_0p2ms.DTA'), 'Chrono item name should use the file name.');
    assert(numel(item.t) == 244 && numel(item.Vf) == 244 && numel(item.Im) == 244, ...
        'Legacy-compatible chrono vectors should be populated.');
    assert(isequal(item.t, item.t_s), 'Unit-explicit t_s should mirror legacy t.');
    assert(isequal(item.Vf, item.Vf_V), 'Unit-explicit Vf_V should mirror legacy Vf.');
    assert(isequal(item.Im, item.Im_A), 'Unit-explicit Im_A should mirror legacy Im.');
    assert(item.n == numel(item.t), 'Item sample count should match the time vector.');
    assert(strcmp(item.message, 'Using table: Curve'), 'Main-curve message should preserve legacy wording.');
    assert(item.pulse.ok, item.pulseMessage);

    assert(isfield(item, 'alignTime_s') && isnan(item.alignTime_s), ...
        'Reusable chrono item construction should not perform app-specific alignment.');
    assert(isfield(item, 'tAligned_s') && isempty(item.tAligned_s), ...
        'Reusable chrono item construction should leave aligned time for app workflow code.');
end
