function test_util_functions()
%TEST_UTIL_FUNCTIONS Focused checks for extracted low-risk utilities.

    item = struct('a', 1);
    out = gamrywb.util.appendStruct(struct([]), item);
    assert(isequal(out, item), 'appendStruct should return item for empty input.');
    out = gamrywb.util.appendStruct(out, struct('a', 2));
    assert(numel(out) == 2 && out(2).a == 2, 'appendStruct should append to a struct array.');

    assert(strcmp(gamrywb.util.shortName('/tmp/Pt 1.DTA'), 'Pt 1.DTA'), 'shortName should preserve base name and extension.');
    assert(strcmp(gamrywb.util.csvEscape('a"b'), 'a""b'), 'csvEscape should double quotes.');

    assert(gamrywb.util.parsePositiveScalar('2.5') == 2.5, 'parsePositiveScalar should parse positive text.');
    assert(isnan(gamrywb.util.parsePositiveScalar('-1')), 'parsePositiveScalar should reject nonpositive values.');

    assert(gamrywb.util.nearestIndex([1 5 8], 6) == 2, 'nearestIndex should return nearest element index.');

    assert(gamrywb.util.interp1Safe([0 2], [10 14], 1) == 12, ...
        'interp1Safe should interpolate finite vectors.');
    assert(isnan(gamrywb.util.interp1Safe([0 2], [10 NaN], 1)), ...
        'interp1Safe should return NaN when source vectors contain NaN.');

    m = gamrywb.util.medianInWindow([1 2 3], [1 NaN 5], 1, 3);
    assert(m == 3, 'medianInWindow should omit NaN values.');

    expected = matlab.lang.makeValidName('Pt 1.DTA');
    assert(strcmp(gamrywb.util.sanitizeFieldName('Pt 1.DTA'), expected), 'sanitizeFieldName should match makeValidName.');
end
