function test_makeChronoItem()
%TEST_MAKECHRONOITEM Verify chrono item construction and gap alignment.

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

    [aligned, msg] = gamrywb.analysis.alignChronoByPulseGap(item);
    assert(abs(aligned.alignTime - 1.22e-3) < 1e-12, 'Alignment should use blank-gap center.');
    assert(isequal(aligned.tAligned, aligned.tAligned_s), 'Normalized aligned time should mirror legacy field.');
    assert(abs(aligned.tAligned(1) - (aligned.t(1) - 1.22e-3)) < 1e-15, ...
        'Aligned time vector should subtract the gap center.');
    assert(contains(msg, 'aligned to cathodic/anodic blank center'), 'Alignment message should match legacy wording.');

    fallback = struct();
    fallback.name = 'synthetic';
    fallback.t = [0.1; 0.2; 0.3];
    fallback.pulse = gamrywb.analysis.emptyPulse();
    fallback.pulseMessage = 'no pulse';
    [fallback, fallbackMsg] = gamrywb.analysis.alignChronoByPulseGap(fallback);
    assert(abs(fallback.alignTime - 0.1) < 1e-15, 'Missing pulse gap should align to first sample.');
    assert(all(abs(fallback.tAligned - [0; 0.1; 0.2]) < 1e-12), ...
        'Fallback aligned time should subtract the first sample.');
    assert(strcmp(fallbackMsg, 'synthetic: pulse gap not found, fallback to first sample (no pulse).'), ...
        'Fallback message should preserve legacy wording.');
end
