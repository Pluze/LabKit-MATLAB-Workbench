function value = itemScanRate(item)
    if isfield(item, 'scanRate')
        value = item.scanRate;
    elseif isfield(item, 'scanRate_V_per_s')
        value = item.scanRate_V_per_s;
    else
        value = NaN;
    end
end
