function item = makeChronoFixtureItem(filename, itemName)
%MAKECHRONOFIXTUREITEM Build a cross-owner synthetic chrono item for app tests.

    if nargin < 1 || isempty(filename)
        filename = 'chrono_chronopot_current_pulse_0p2ms.DTA';
    end

    fixture = testfixtures.dtaFixturePath(filename);
    if nargin < 2 || isempty(itemName)
        itemName = filename;
    end

    item = struct();
    item.filepath = fixture;
    item.name = itemName;
    [loadedItem, status] = labkit.dta.loadFile(fixture, "chrono");
    assert(status.ok, status.message);
    item.meta = loadedItem.meta;
    item.tables = loadedItem.tables;
end
