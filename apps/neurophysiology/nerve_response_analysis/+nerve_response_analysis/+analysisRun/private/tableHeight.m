function n = tableHeight(value)
    if istable(value)
        n = height(value);
    else
        n = 0;
    end
end
