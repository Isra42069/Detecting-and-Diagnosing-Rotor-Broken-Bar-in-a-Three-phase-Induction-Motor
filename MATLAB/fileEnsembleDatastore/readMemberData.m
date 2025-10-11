function T = readMemberData(filename, requestedVars)
% readMemberData — load requested variables from a .mat member file
% and return a ONE-ROW table with one column per requested variable.
%
% requestedVars is a string/cellstr array of names that appear in ens.DataVariables
% or ens.ConditionVariables. You may also request derived variables
% like "Vib_acpi_env" or "Ia_env_ps" which we compute here.

    % Normalize to cellstr for load, strcmp, etc.
    if isstring(requestedVars); requestedVars = cellstr(requestedVars); end

    % We'll need to load some base variables to compute derived ones.
    needsVibEnv = any(strcmp(requestedVars,'Vib_acpi_env'));
    needsIaPs   = any(strcmp(requestedVars,'Ia_env_ps'));

    % Figure out the minimal set to load
    baseToLoad = intersect(requestedVars, {'Va','Vb','Vc','Ia','Ib','Ic', ...
                                           'Vib_acpi','Vib_carc','Vib_acpe', ...
                                           'Vib_axial','Vib_base','Trigger', ...
                                           'Health','Load','Fs_vib','Fs_elec'});

    % Add dependencies for derived variables
    if needsVibEnv && ~any(strcmp(baseToLoad,'Vib_acpi')); baseToLoad{end+1} = 'Vib_acpi'; end
    if needsVibEnv && ~any(strcmp(baseToLoad,'Fs_vib'));   baseToLoad{end+1} = 'Fs_vib';   end

    if needsIaPs && ~any(strcmp(baseToLoad,'Ia'));         baseToLoad{end+1} = 'Ia';       end
    if needsIaPs && ~any(strcmp(baseToLoad,'Fs_elec'));    baseToLoad{end+1} = 'Fs_elec';  end

    % Load only what we need (if nothing, load nothing)
    S = struct();
    if ~isempty(baseToLoad)
        S = load(filename, baseToLoad{:});
    end

    % Build the one-row table result
    T = table();

    % Helper to wrap raw arrays/timeseries into a cell so table has scalar entries
    wrapCell = @(x) {x};

    % Populate requested variables
    for i = 1:numel(requestedVars)
        v = requestedVars{i};

        switch v
            % Direct variables from file
            case {'Va','Vb','Vc','Ia','Ib','Ic', ...
                  'Vib_acpi','Vib_carc','Vib_acpe', ...
                  'Vib_axial','Vib_base','Trigger'}
                assert(isfield(S,v), "readMemberData:MissingVar", ...
                    "Variable '%s' not found in %s", v, filename);
                T.(v) = wrapCell(S.(v));

            case {'Health','Load','Fs_vib','Fs_elec'}
                % Store scalars/strings as-is (still wrap in cell so table stays 1xN)
                assert(isfield(S,v), "readMemberData:MissingVar", ...
                    "Variable '%s' not found in %s", v, filename);
                T.(v) = wrapCell(S.(v));

            % Derived variables computed here
            case 'Vib_acpi_env'
                % Requires Vib_acpi (vector or timeseries) and Fs_vib
                assert(isfield(S,'Vib_acpi') && isfield(S,'Fs_vib'), ...
                    "readMemberData:DepsMissing", ...
                    "Need Vib_acpi and Fs_vib in %s to compute Vib_acpi_env.", filename);

                vib = S.Vib_acpi;
                Fs  = S.Fs_vib;
                % Get raw data vector regardless of type
                x = extractData(vib);

                % Envelope via bandpass + envelope
                % Adjust band if your ROI differs; this matches your snippet
                y = bandpass(x, [900 1300], Fs);
                env = envelope(y);

                T.(v) = wrapCell(struct('Data', env, 'Fs', Fs)); % simple struct with Data/Fs

            case 'Ia_env_ps'
                % Envelope of current Ia, then power spectrum
                assert(isfield(S,'Ia') && isfield(S,'Fs_elec'), ...
                    "readMemberData:DepsMissing", ...
                    "Need Ia and Fs_elec in %s to compute Ia_env_ps.", filename);

                ia = extractData(S.Ia);
                Fe = S.Fs_elec;

                % A common trick: demodulate via absolute value or Hilbert envelope
                % Here, use envelope to highlight low-freq modulation, then pspectrum
                envIa = envelope(double(ia));
                % Return the spectrum as a struct with frequency and power for flexibility
                [P,F] = pspectrum(envIa, Fe);

                T.(v) = wrapCell(struct('F', F, 'P', P, 'Fs', Fe));

            otherwise
                error("readMemberData:UnknownVar", ...
                    "Requested variable '%s' not supported by readMemberData.", v);
        end
    end
end

% Helper: extract raw data from either numeric vector or timeseries-like struct
function x = extractData(sig)
    if isnumeric(sig)
        x = sig(:);
    elseif isstruct(sig) && isfield(sig,'Data')
        x = sig.Data(:);
    elseif isa(sig,'timeseries')
        x = sig.Data(:);
    else
        error("readMemberData:UnknownSignalType", ...
              "Unsupported signal type for envelope/pspectrum.");
    end
end
