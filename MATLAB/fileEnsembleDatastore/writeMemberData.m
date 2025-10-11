function writeMemberData(filename, S)
% writeMemberData — append variables to a member file.
% S must be a struct whose fieldnames are the variable names to write.

    if ~isstruct(S)
        error("writeMemberData:InputNotStruct", "Second argument must be a struct.");
    end

    % -append keeps existing variables
    save(filename, '-append', '-struct', 'S');
end
