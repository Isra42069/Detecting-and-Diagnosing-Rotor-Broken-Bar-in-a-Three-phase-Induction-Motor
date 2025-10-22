
function TT = getSignal(mfile, signname, Fs)
 % Extract a 1.0 second portion of the signal after 10 seconds of measurements.
 if isstring(signname)
    signname = char(signname);
end

 signame = char(signname);
 
n = size(mfile, signame, 1);
t = (0:n-1)' / Fs;
I = find((t >= 10.0) & (t <= 11.0)); % 1.0 sec of data 
TT = timetable(mfile.(signname)(I,1), 'VariableNames' , "Data" , 'RowTimes' , seconds(t(I)));
end
