filename = "experimental_database_short.zip";
if ~exist(filename,'file')
  url = "https://ssd.mathworks.com/supportfiles/predmaint/broken-rotor-bar-fault-data/" + filename;
  websave(filename,url);
end
>> unzip(filename)
>> numExperiments = 2;
>> % Names of the original data files restored from the zip archive.
files = [ ...
  "struct_rs_R1.mat", ...
  "struct_r1b_R1.mat", ...
  "struct_r2b_R1.mat", ...
  "struct_r3b_R1.mat", ...
  "struct_r4b_R1.mat", ...
  ];

% Rotor conditions (that is, number of broken bars) corresponding to original data files.
health = [
  "healthy", ...
  "broken_bar_1", ...
  "broken_bar_2", ...
  "broken_bar_3", ...
  "broken_bar_4", ...
  ];

Fs_vib = 7600; % Sampling frequency of vibration signals in Hz.
Fs_elec = 50000; % Sampling frequency of electrical signals in Hz.
folder = 'data_files';
if ~exist(folder, 'dir')
  mkdir(folder);
end
>> % Iterate over the number of broken rotor bars.
for i = 1:numel(health)
  fprintf('Processing data file %s\n', files(i))

  % Load the original data set stored as a struct.
  S = load(files(i));
  fields = fieldnames(S);
  dataset = S.(fields{1});

  loadLevels = fieldnames(dataset);
  % Iterate over load (torque) levels in each data set.
  for j = 1:numel(loadLevels)
    experiments = dataset.(loadLevels{j});
    data = struct;

    % Iterate over the given number of experiments for each load level.
    for k = 1:numExperiments
      signalNames = fieldnames(experiments(k));
      % Iterate over the signals in each experimental data set.
      for l = 1:numel(signalNames)
        % Experimental (electrical and vibration) data
        data.(signalNames{l}) = experiments(k).(signalNames{l});
      end

      % Operating conditions
      data.Health = health(i);
      data.Load = string(loadLevels{j});

      % Constant parameters
      data.Fs_vib = Fs_vib;
      data.Fs_elec = Fs_elec;

      % Save memberwise data.
      name = sprintf('rotor%db_%s_experiment%02d',  i-1, loadLevels{j}, k);
      fprintf('\tCreating the member data file %s.mat\n', name)
      filename = fullfile(pwd, folder, name);
      save(filename, '-v7.3', '-struct', 'data'); % Save fields as individual variables.
    end
  end
end
% Iterate over the number of broken rotor bars.
for i = 1:numel(health)
  fprintf('Processing data file %s\n', files(i))

  % Load the original data set stored as a struct.
  S = load(files(i));
  fields = fieldnames(S);
  dataset = S.(fields{1});

  loadLevels = fieldnames(dataset);
  % Iterate over load (torque) levels in each data set.
  for j = 1:numel(loadLevels)
    experiments = dataset.(loadLevels{j});
    data = struct;

    % Iterate over the given number of experiments for each load level.
    for k = 1:numExperiments
      signalNames = fieldnames(experiments(k));
      % Iterate over the signals in each experimental data set.
      for l = 1:numel(signalNames)
        % Experimental (electrical and vibration) data
        data.(signalNames{l}) = experiments(k).(signalNames{l});
      end

      % Operating conditions
      data.Health = health(i);
      data.Load = string(loadLevels{j});

      % Constant parameters
      data.Fs_vib = Fs_vib;
      data.Fs_elec = Fs_elec;

      % Save memberwise data.
      name = sprintf('rotor%db_%s_experiment%02d',  i-1, loadLevels{j}, k);
      fprintf('\tCreating the member data file %s.mat\n', name)
      filename = fullfile(pwd, folder, name);
      save(filename, '-v7.3', '-struct', 'data'); % Save fields as individual variables.
    end
  end
end
location = fullfile(pwd, folder);
ens = fileEnsembleDatastore(location,'.mat');

%%readMemberData — Extract requested variables stored in the file. The function returns a table row containing one table variable for each requested variable.
%%writeMemberData — Take a structure and write its variables to a data file as individual stored variables.
%% check fileEnsembleDatastore

ens.ReadFcn = @readMemberData;
ens.WriteToMemberFcn = @writeMemberData;

% Make sure these lists include ONLY names your reader can supply
ens.DataVariables = [...
   "Va"; "Vb"; "Vc"; "Ia"; "Ib"; "Ic"; ...
   "Vib_acpi"; "Vib_carc"; "Vib_acpe"; "Vib_axial"; "Vib_base"; "Trigger"; ...
   "Fs_vib"; "Fs_elec"; ...
   "Vib_acpi_env"; "Ia_env_ps"  % derived
];
ens.ConditionVariables = ["Health"; "Load"];

% Only pick what you need to read now
ens.SelectedVariables = ["Ia"; "Vib_acpi"; "Health"; "Load"; "Vib_acpi_env"; "Ia_env_ps"];
ens
T = read(ens);  % 1-row table per member

% Power spectrum of vibration signal, Vib_acpi
vib = T.Vib_acpi{1};
pspectrum(vib, Fs_vib);
annotation("textarrow", [0.45 0.38], [0.65 0.54], "String", "Fault frequency region of interest")

% Envelop of vibration signal
y = bandpass(vib, [900 1300], Fs_vib);
envelope(y)
axis([0 800 -0.5 0.5])

