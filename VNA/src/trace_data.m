%{
Copyright (C) 2021-2023 University of Waterloo - All Rights Reserved.

You may use, distribute and/or modify this code under the
terms of the MIT License.

You should have received a copy of the MIT License along 
with the code; see the file LICENSE. 
If not, see <https://opensource.org/license/mit/>.
%}


% Clear previous resources
clear;
close all;

%% Script Configurations
ENAConf = struct();
ENAConf.resourceID = 'GPIB0::16::INSTR';    % VISA Reource ID of the VNA machine
ENAConf.autoTrigger = true;                 % Continuous trigger: true - internal trigger; false - bus trigger
ENAConf.enabledTraces = [1, 2];             % Trace numbers we want to record (e.g., [1, 2, 3, 4])
ENAConf.enablePlot = true;                  % Plot data on graph as we collect
ENAConf.enableSave = true;                  % Save data to file
ENAConf.checkpointFrames = 50;              % Save data to file every n frames
ENAConf.totalTime = 300;                     % Total duration of the experiment in seconds


%% Sweep and Collect Data from Device
ENA = initResource(ENAConf);

frameInd = 0;
filename = strcat(string(datetime, "yyMMddHHmmss"), "-data.mat");

% Initialize data struct
data = struct();
data.enabledTraces = ENAConf.enabledTraces;
data.totalTime = ENAConf.totalTime;
for traceInd = ENAConf.enabledTraces
    data.(strcat("trace", string(traceInd))) = struct();
end

% Timer starts
tic

while toc < ENAConf.totalTime
    if (~ENAConf.autoTrigger)
        triggerSweep(ENA);
    end

    if frameInd == 0
        frequency = readFrequencyData(ENA);
        data.frequency = frequency;
    end

    for traceInd = ENAConf.enabledTraces
        traceStr = strcat("trace", string(traceInd));
        
        [cdata, traceFormat] = readTraceData(ENA, traceInd);

        if frameInd == 0
            data.(traceStr).traceFormat = traceFormat;
            data.(traceStr).cdata = cdata;
        else
            data.(traceStr).cdata = [data.(traceStr).cdata; cdata];
        end
    
        if ENAConf.enablePlot
            plotGraph(frequency, cdata, traceFormat, traceInd, max(ENAConf.enabledTraces));
            pause(0.01);
        end
    end

    frameInd = frameInd + 1;
    data.totalFrames = frameInd;

    if ENAConf.enableSave && mod(frameInd, ENAConf.checkpointFrames) == 0
        saveData(filename, data);
    end
end

if ENAConf.enableSave
    saveData(filename, data);
    fprintf(strcat('Data saved to file ', filename, '\n'));
end

clearResource(ENA);

fprintf(strcat('Total number of frames:\t', string(frameInd), '\n'));

% Timer stops
toc


%% Functions
function ENA = initResource(ENAConf)
    % Remove all interfaces to instrument
    instrreset
    % find all previously created objects
    oldobjs = instrfind;
    
    % If there are any existing objects
    if (~isempty(oldobjs))
        % close the connection to the instrument
        fclose(oldobjs);
        % and free up the object resources
        delete(oldobjs);
    end
     
    % Remove the object list from the workspace.
    clear oldobjs;
    
    % Define ENA interface, this is the VISA resource string. Replace this VISA
    % resource string with your ENA VISA resource string as appropriate. 
    ENA = visadev(ENAConf.resourceID);
    
    % Buffer size must precede open command
    set(ENA,'InputBufferSize', 640000);
    set(ENA,'OutputBufferSize', 640000);
    
    % Open session to ENA based on VISA resource string
    fopen(ENA);
    
    % Clear the event status registers and all errors which may be in the ENA's error queue.
    fprintf(ENA, '*CLS');
    
    % Check to ensure the error queue is clear. Response should be '+0, No Error'
    fprintf(ENA, 'SYST:ERR?');
    errIdentifyStart = fscanf(ENA, '%c');
    fprintf(strcat('\nThe initial error query results string is:\t',errIdentifyStart))
    
    % Query instrument identification string
    fprintf(ENA, '*IDN?'); 
    idn = fscanf(ENA, '%c');
    fprintf(strcat('\nThe identification string is:\t',idn))
    
    % ENA timeout is set to 15 (seconds) to allow for longer sweep times. 
    set(ENA, 'Timeout', 15);
    
    % Trigger mode is set to initiate continuous on and trigger source as bus
    fprintf(ENA, 'INIT:CONT ON');

    if ENAConf.autoTrigger
        fprintf(ENA, 'TRIG:SOUR INT');
    else
        fprintf(ENA, 'TRIG:SOUR BUS');
    end
end


function triggerSweep(ENA)
    % Trigger a single sweep and wait for trigger completion via *OPC? query i.e. (operation complete). 
    fprintf(ENA, 'TRIG:SING;*OPC?');
    opComplete = fscanf(ENA, '%s');
end


function frequency = readFrequencyData(ENA)
    % Swap byte order on data query return.
    fprintf(ENA,'FORM:BORD SWAP');
    
    % Set Trace Data read or return format as binary bin block real 64-bit values
    fprintf(ENA, 'FORM:DATA REAL');

    % Read the stimulus values
    fprintf(ENA,'SENSE:FREQ:DATA?');
    frequency = binblockread(ENA,'float64');
    % Binblock read has a 'hanging line feed' that must be read and disposed
    fscanf(ENA, '%c');

    % Reshape array of numbers into a row in matrix
    frequency = frequency.';
end


function [trimmedCdata, traceFormat] = readTraceData(ENA, traceInd)
    traceParam = strcat("TRAC", string(traceInd));

    % Determine display format and then set variable to allow or dis-allow
    % a plot at the end of the application. 
    % Define a string array of all the single element format display modes
    supportedSingleModeFormats = {'MLOG', 'PHAS', 'GDEL', 'MLIN', 'SWR', 'REAL', 'IMAG', 'UPH', 'PPH'};
    % Query the current ENA display format 
    dataQueryForm = strcat("CALC:", traceParam, ":FORM?");
    fprintf(ENA, dataQueryForm);
    traceFormat = fscanf(ENA,'%s');
    % A function call to the 'sum' function and 'strcmp' string comparison function to determine 
    % if the current ENA measurement format supports an 'easy' 
    % stimulus / response plot method within this application.
    okToPlot = sum(strcmp(traceFormat,supportedSingleModeFormats));
    
    % To select the 'FORMATTED DATA' which matches the display use the 
    % 'CALC:DATA:FDATA? query. Alternatively, to select the underlying real and 
    % imaginary pairs which the formatted data is based upon use 
    % 'CALC:DATA:SDATA?' query. Uncomment one of the following 
    dataQueryType = strcat("CALC:", traceParam, ":DATA:FDATA?");
    % dataQueryType = 'CALC:TRAC1:DATA:SDATA?';
    fprintf(ENA, dataQueryType);
    
    % Read return data as binary bin block real 64-bit values. 
    cData = binblockread(ENA, 'float64');
    
    % Binblock read has a 'hanging line feed' that must be read and disposed
    fscanf(ENA, '%c');
    
    % Now trim the '0' zero value place holders.
    trimmedCdata = cData(1:2:end);
    % fprintf('\nThe trimmed FDATA, i.e. Formatted data results are:\n')
    % disp(trimmedCdata)

    % Reshape array of numbers into a row in matrix
    trimmedCdata = trimmedCdata.';
end


function plotGraph(frequency, cdata, traceFormat, traceInd, totalTraces)
    subplot(totalTraces, 1, traceInd);
    plot(frequency, cdata);

    plotTitle = "VNA Formatted Data";
    xlabel("Frequency (Hz)");
    if strcmp(traceFormat, 'MLOG') == 1
        plotTitle = plotTitle + ' - Log Magnitude';
        ylabel("Magnitude (dB)");
    elseif strcmp(traceFormat, 'MLIN') == 1
        plotTitle = plotTitle + ' - Linear Magnitude';
        ylabel("Magnitude (mU)");
    elseif strcmp(traceFormat, 'PHAS') == 1
        plotTitle = plotTitle + ' - Phase';
        ylabel("Phase (deg)");
    elseif strcmp(traceFormat, 'PPH') == 1
        plotTitle = plotTitle + ' - Positive Phase';
        ylabel("Phase (deg)");
    end
    title(plotTitle);
end


function saveData(filename, data)
    save(filename, "data");
end


function clearResource(ENA)
    % Return data transfer format back to ASCII string format
    fprintf(ENA, 'FORM:DATA ASCII');
    
    % Return trigger source to internal and free running
    fprintf(ENA, 'TRIG:SOUR INT');
    
    % As a last step query the ENA error queue a final time and ensure no errors have
    % occurred since initiation of program. 
    fprintf(ENA, 'SYST:ERR?');
    errIdentifyStop = fscanf(ENA, '%c');
    fprintf(strcat('\nThe final error query results string is:\t',errIdentifyStop,'\n'))
    
    % Close session connection
    clear ENA;
end

