function increment = observedIncrement(values)
%OBSERVEDINCREMENT Estimate a lower typical nonzero change in native units.
% Immediate reversing edges are poor evidence of sustained instrument levels.
numericalFloor = 64*eps(max([abs(values(:)); realmin]));
steps = diff(values(:));
increment = numericalFloor;
if isempty(steps), return; end
reverses = sign(steps(1:end-1)).*sign(steps(2:end)) < 0;
retained = sort(abs(steps(~([false; reverses] | [reverses; false]) & ...
    abs(steps)>numericalFloor)));
if ~isempty(retained)
    increment = retained(ceil(numel(retained)/4));
end
end
