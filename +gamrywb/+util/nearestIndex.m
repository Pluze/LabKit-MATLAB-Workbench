function idx = nearestIndex(x, xq)
%NEARESTINDEX Return index of the element nearest to a query value.

    [~, idx] = min(abs(x - xq));
end
