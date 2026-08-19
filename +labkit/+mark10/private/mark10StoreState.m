function state = mark10StoreState(state, key, value)
%MARK10STORESTATE Update one entry in a Mark-10 handle-state map.
state(char(key)) = value;
end
