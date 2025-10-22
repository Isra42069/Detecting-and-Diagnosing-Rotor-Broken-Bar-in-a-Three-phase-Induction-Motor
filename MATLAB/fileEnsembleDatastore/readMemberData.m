function T = readMemberData(filename, variables)
 % Read variables from a fileEnsembleDatastore 
% 
% Inputs: 
% filename - file to read, specified as a string 
% variables - variable names to read, specified as a string array 
% Variables must be a subset of SelectedVariables specified in 
% the fileEnsembleDatastore. 
% Output: 
% T - a table with a single row

mfile = matfile(filename); % Allows partial loading
if isstring(filename)
    filename = char(filename);
end
% Read condition variables directly from the top-level structure fields
T = table();
for i = 1:numel(variables)
  var = variables(i);

  switch var
     case { 'Health' , 'Load' }
       % Condition variables
      val = mfile.(var);
    case { 'Va' , 'Vb' , 'Vc' , 'Ia' , 'Ib' , 'Ic' }
       % Electrical signals
      val = getSignal(mfile, var, mfile.Fs_elec);
    case { 'Vib_acpi' , 'Vib_carc' , 'Vib_acpe' , 'Vib_axial' , 'Vib_base' , 'Trigger' }
       % Vibration signals
      val = getSignal(mfile, var, mfile.Fs_vib);
    case { 'Vib_acpi_env' }
       % Synthetic envelope signals for vibration data 
      sig = regexprep(var, '_env' , '' );
      TT = getSignal(mfile, sig, mfile.Fs_vib);
      % Envelope of band-pass filtered signal
      y = bandpass(TT.Data, [900 1300], mfile.Fs_vib);
      yUpper = envelope(y);
      val = timetable(yUpper, 'VariableNames' , "Data" , 'RowTimes' , TT.Time);
     case { 'Ia_env' }
       % Synthetic envelope signals for electrical data 
      sig = regexprep(var, '_env' , '' );
      TT = getSignal(mfile, sig, mfile.Fs_elec);
      % Envelope of band-pass filtered signal
      y = bandpass(TT.Data, [900 1300], mfile.Fs_elec);
      yUpper = envelope(y);
      val = timetable(yUpper, 'VariableNames' , "Data" , 'RowTimes' , TT.Time);
     case { 'Ia_env_ps' }
       % Synthetic envelope spectra for electrical data 
      sig = regexprep(var, '_env_ps' , '' );
      TT = getSignal(mfile, sig, mfile.Fs_elec);
      % Envelope spectrum of band-pass filtered signal 
      [ES,F] = envspectrum(TT, 'Method' , 'hilbert' , 'Band' , [900 1300]);
      val = [F,ES];
    otherwise 
      % Other features and signals.
      val = mfile.(var);
  end

  if numel(val) > 1
    val = {val};
  end

  % Add the data to the output table, using the variable name.
  T.(var) = val;
end 
end
