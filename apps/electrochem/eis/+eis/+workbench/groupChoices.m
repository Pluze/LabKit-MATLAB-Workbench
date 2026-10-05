function choices = groupChoices(groups)
%GROUPCHOICES Own the unselected target label and existing group choices.
choices = ["(select group)", string({groups.name})];
end
