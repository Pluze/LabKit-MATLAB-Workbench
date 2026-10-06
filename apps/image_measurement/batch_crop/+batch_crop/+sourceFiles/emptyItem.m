function item = emptyItem()
%EMPTYITEM Add decoded source values to the crop-task defaults.
% App-local reader/algorithm value; task identity stays in project.inputs.
item = rmfield(batch_crop.cropTasks.emptyTask(), "sourceId");
item.path = "";
item.image = [];
end
