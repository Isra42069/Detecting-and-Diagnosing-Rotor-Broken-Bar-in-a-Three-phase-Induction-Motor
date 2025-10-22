function writeMemberData(filename, data)
 % Write data into the fileEnsembleDatastore. 
% 
% Inputs: 
% filename - a string for the file name to write 
% data - a data structure to write to the file

% Save fields as individual variables. 
save(filename, '-append' , '-struct' , 'data' );
 end
