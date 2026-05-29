function item = makeChronoFixtureItem(filename, itemName)
%MAKECHRONOFIXTUREITEM Build the minimal chrono item shape used by app tests.

    if nargin < 1 || isempty(filename)
        filename = 'chrono_chronopot_current_pulse_0p2ms.DTA';
    end

    fixture = demoFixturePath(filename);
    if nargin < 2 || isempty(itemName)
        itemName = filename;
    end

    item = struct();
    item.filepath = fixture;
    item.name = itemName;
    [item.meta, item.tables] = gamrywb.io.parseChronoDTA(fixture);
end
