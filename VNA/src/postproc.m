%{
Copyright (C) 2021-2023 University of Waterloo - All Rights Reserved.

You may use, distribute and/or modify this code under the
terms of the MIT License.

You should have received a copy of the MIT License along 
with the code; see the file LICENSE. 
If not, see <https://opensource.org/license/mit/>.
%}


%% Parser configurations
Settings = struct();
Settings.BaselineType = "avg";          % "avg" or "med" to use average or median as baseline type

Settings.PlotHeatMap = true;
Settings.PlotNormalizedHeatMap = true;
Settings.PlotNormalizedHeatMapGrouped = true;
Settings.PlotNormalizedHeatMapGroupedCI = true;
Settings.PlotAveragedFramesOverTime = true;
Settings.PlotAveragedFramesOverFreq = true;
Settings.PlotAveragedFramesOverFreqGrouped = true;
Settings.PlotAveragedFramesOverNarrowFreq = true;
Settings.PlotAveragedFramesOverNarrowFreqGrouped = true;
Settings.PlotFrames = true;

Settings.NormalizedHeatMapMLOGCLimit = [-10.5 10.5];
Settings.NormalizedHeatMapPHASCLimit = [-1.1 1.1];
Settings.NormalizedGroupedHeatMapXBatchSize = 7;
Settings.NormalizedGroupedHeatMapYBatchSize = 30;
Settings.NormalizedGroupedHeatMapMLOGColors = 21;
Settings.NormalizedGroupedHeatMapPHASColors = 11;

Settings.AveragedFramesBatchSize = 30;
Settings.AveragedFramesFreqStart = 5.2086e9;
Settings.AveragedFramesFreqEnd = 5.2114e9;
Settings.FreqGroupName = "5.2086 - 5.2114 GHz";
Settings.AveragedFramesFreqStart2 = 0;
Settings.AveragedFramesFreqEnd2 = 5.18e9;
Settings.FreqGroupName2 = "5.1772 - 5.1800 GHz";
Settings.AveragedFramesFreqStart3 = 0;
Settings.AveragedFramesFreqEnd3 = 5.2142e9;
Settings.FreqGroupName3 = "5.2114 - 5.2142 GHz";

Settings.PlotTitles = true;
Settings.TickLabelRotation = 0;
Settings.BaselineLength = 10;
Settings.AxisFontSize = 20;
Settings.AxisLimitRounding = 2;
Settings.LineWidth = 2;
Settings.FillAlpha = 0.5;
Settings.PlotPosition = [100 100 900 650];
Settings.AveragedFramesOverNarrowFreqCI = true;
Settings.AveragedFramesOverNarrowFreqGroupedCI = true;


% Directory path
outputDir = "~/fire-detection/VNA/graphs/";

% Experiment recordings and their corresponding baseline recordings
experiments = ["baseline-5ghz-T1", "baseline-5ghz-T2", "baseline-5ghz-T3", ...
               "fire-5ghz-T1", "fire-5ghz-T2", "fire-5ghz-T3", ...
               "baseline-no-wifi-T1", "baseline-no-wifi-T2", "baseline-no-wifi-T3", ...
               "fire-T1", "fire-no-wifi-T1", "fire-no-wifi-T2", ...
               "baseline-T1", "baseline-T2", "baseline-T3", ...
               "baseline-1m-T1", "baseline-1m-T2", "baseline-3m-low-T1", "baseline-3m-low-T2", ...
               "baseline-3m-T1", "baseline-3m-T2", "baseline-wood-3m-T1", "baseline-wood-3m-T2", ...
               "baseline-wood-3m-T3", "baseline-wood-3m-T4", "fire-3m-low-T1", "fire-3m-low-T2", ...
               "fire-3m-T1", "fire-3m-T2", "fire-5ghz-T4", "fire-wood-3m-T1", "fire-wood-3m-T2", ...
               "moving-1m-T1", "moving-1m-T2", "moving-3m-T1", "moving-3m-T2"];
baselines = ["baseline-5ghz-T2", "baseline-5ghz-T3", "baseline-5ghz-T1", ...
             "baseline-5ghz-T1", "baseline-5ghz-T2", "baseline-5ghz-T3", ...
             "baseline-no-wifi-T2", "baseline-no-wifi-T3", "baseline-no-wifi-T1", ...
             "baseline-T1", "baseline-no-wifi-T1", "baseline-no-wifi-T2", ...
             "baseline-T2", "baseline-T3", "baseline-T1", ...
             "baseline-1m-T2", "baseline-1m-T1", "baseline-3m-low-T2", "baseline-3m-low-T1", ...
             "baseline-3m-T2", "baseline-3m-T1", "baseline-wood-3m-T2", "baseline-wood-3m-T1", ...
             "baseline-wood-3m-T4", "baseline-wood-3m-T3", "baseline-3m-low-T1", "baseline-3m-low-T2", ...
             "baseline-3m-T1", "baseline-3m-T2", "baseline-5ghz-T4", "baseline-wood-3m-T1", "baseline-wood-3m-T3", ...
             "baseline-1m-T1", "baseline-1m-T2", "baseline-3m-T1", "baseline-3m-T2"];


% Create output directory
[~,~] = mkdir(outputDir);

% Parse data for each experiment
if length(experiments) ~= length(baselines)
    disp("ERROR: number of experiments does not match number of baselines");
    return;
end

for expInd = 1:length(experiments)
    parseDataFile(experiments(expInd), baselines(expInd), outputDir, Settings);
end

close all

%% Parser function
function parseDataFile(exp, baseline, outputDir, Settings)
    fprintf("---------------------------------------------------------\n");
    fprintf("Experiment: %s\n", exp);
    fprintf("Baseline: %s\n", baseline);
    
    [~,~] = mkdir(outputDir + exp);

    if Settings.PlotFrames
        [~,~] = mkdir(fullfile(outputDir, exp, "frames"));
    end

    expData = load(exp + ".mat").data;
    if baseline ~= ""
        baselineData = load(baseline + ".mat").data;
    end

    totalTraces = length(expData.enabledTraces);
    FPS = floor(expData.totalFrames / expData.totalTime);
    limitMax = zeros(1, totalTraces);
    limitMin = zeros(1, totalTraces);

    for traceInd = expData.enabledTraces
        traceName = strcat("trace", string(traceInd));
        traceData = expData.(traceName);

        % Unwrap phase information
        if strcmp(traceData.traceFormat, "PHAS") || strcmp(traceData.traceFormat, "PPH")
            traceData.cdata = unwrap(unwrap(deg2rad(traceData.cdata), [], 1), [], 2);
            expData.(traceName).cdata = traceData.cdata;
        end

        if baseline ~= ""
            baselineTraceData = baselineData.(traceName);

            % Unwrap baseline phase information
            if strcmp(baselineTraceData.traceFormat, "PHAS") || strcmp(baselineTraceData.traceFormat, "PPH")
                baselineTraceData.cdata = unwrap(unwrap(deg2rad(baselineTraceData.cdata), [], 1), [], 2);
                baselineData.(traceName).cdata = baselineTraceData.cdata;
            end
    
            if (size(expData.frequency, 2) ~= size(traceData.cdata, 2))
                 disp("ERROR: dimension of frequency data does not match dimension of cdata");
                 return;
            end
    
            if (size(expData.frequency, 2) ~= size(expData.frequency, 2))
                disp("ERROR: inconsistent frequency dimension with baseline");
                return;
            end
    
            if (traceData.traceFormat ~= baselineTraceData.traceFormat)
                disp("ERROR: inconsistent trace format with baseline");
                return;
            end
    
            baselineAvg = mean(baselineTraceData.cdata, 1);
            baselineMed = median(baselineTraceData.cdata, 1);
    
            if Settings.BaselineType == "avg"
                normalizedData = traceData.cdata - baselineAvg;
            elseif Settings.BaselineType == "med"
                normalizedData = traceData.cdata - baselineMed;
            else
                disp("ERROR: incorrect baseline type: " + Settings.BaselineType);
                return;
            end

            expData.(traceName).normalizedData = normalizedData;
        end

        maxVal = max(max(expData.(traceName).cdata));
        minVal = min(min(expData.(traceName).cdata));
        limitMax(traceInd) = ceil(maxVal / 5) * 5;
        limitMin(traceInd) = floor(minVal / 5) * 5;
    end

    % Plot heatmaps
    if Settings.PlotHeatMap
        for traceInd = expData.enabledTraces
            traceData = expData.(strcat("trace", string(traceInd)));
            if (size(expData.frequency, 2) ~= size(traceData.cdata, 2))
                 disp("ERROR: dimension of frequency data does not match dimension of cdata")
            end
    
            if strcmp(traceData.traceFormat, "MLOG")
                % Parse trace data as Log Magnitude
                cdata = flip(traceData.cdata, 1);
                timestamps = flip(linspace(0, expData.totalTime, size(traceData.cdata, 1)));
    
                xdata = expData.frequency / power(10, 9);
                ydata = timestamps;
                h = heatmap(xdata, ydata, cdata);

                hs = struct(h);
                hs.XAxis.TickLabelRotation = Settings.TickLabelRotation;
                if Settings.PlotTitles
                    h.Title = ["Log Magnitude Heatmap - " + exp, ...
                               "Colormap: Signal Strength (dB)"];
                end
                h.XLabel = "Frequency (GHz)";
                h.YLabel = "Time (s)";
                h.GridVisible = false;
                h.Colormap = turbo;
                setupLabelTicks(h, xdata, "X");
                setupLabelTicks(h, ydata, "Y");
                [colormapMin, colormapMax] = getLimits2D(cdata, 10);
                caxis([colormapMin colormapMax]);
                a = annotation('textarrow', [0.975,0.975], [0.5,0.5], ...
                               'String', 'Signal Strength (dBm)', ...
                               'HeadStyle', 'none', 'LineStyle', 'none', ...
                               'HorizontalAlignment', 'center', ...
                               'TextRotation', 90, ...
                               'FontSize', Settings.AxisFontSize);
                set(gca, "FontSize", Settings.AxisFontSize);
                set(gcf, "Position", Settings.PlotPosition);
                
                path = fullfile(outputDir, exp, "heatmap-MLOG");
                savefig(path);
                exportgraphics(h, path + ".png", 'Resolution', 500);
                delete(a);
            elseif strcmp(traceData.traceFormat, "PHAS")
                % Parse trace data as Phase
                cdata = wrapToPi(flip(traceData.cdata, 1));
                %cdata = flip(traceData.cdata, 1);
                timestamps = flip(linspace(0, expData.totalTime, size(traceData.cdata, 1)));
    
                xdata = expData.frequency / power(10, 9);
                ydata = timestamps;
                h = heatmap(xdata, ydata, cdata);
                hs = struct(h);
                hs.XAxis.TickLabelRotation = Settings.TickLabelRotation;
                if Settings.PlotTitles
                    h.Title = ["Phase Heatmap - " + exp, ...
                               "Colormap: Phase (rad)"];
                end
                h.XLabel = "Frequency (GHz)";
                h.YLabel = "Time (s)";
                h.GridVisible = false;
                h.Colormap = parula;
                setupLabelTicks(h, xdata, "X");
                setupLabelTicks(h, ydata, "Y");
                % [colormapMin, colormapMax] = getLimits2D(cdata, 5);
                % caxis([colormapMin colormapMax]);
                caxis([-pi pi]);
                a = annotation('textarrow', [0.975,0.975], [0.5,0.5], ...
                               'String', 'Phase (rad)', ...
                               'HeadStyle', 'none', 'LineStyle', 'none', ...
                               'HorizontalAlignment', 'center', ...
                               'TextRotation', 90, ...
                               'FontSize', Settings.AxisFontSize);
                set(gca, "FontSize", Settings.AxisFontSize);
                set(gcf, "Position", Settings.PlotPosition);
                
                path = fullfile(outputDir, exp, "heatmap-PHAS");
                savefig(path);
                exportgraphics(h, path + ".png", 'Resolution', 500);
                delete(a);
            end
        end
    end

    % Plot normalized heatmaps
    if Settings.PlotNormalizedHeatMap && baseline ~= ""
        disp("Normalized heatmap:")
        for traceInd = expData.enabledTraces
            traceData = expData.(strcat("trace", string(traceInd)));
            normalizedData = traceData.normalizedData;
    
            if strcmp(traceData.traceFormat, "MLOG")
                % Parse trace data as Log Magnitude
                disp("MLOG:")

                cdata = flip(normalizedData, 1);
                timestamps = flip(linspace(0, expData.totalTime, size(normalizedData, 1)));
    
                xdata = expData.frequency / power(10, 9);
                ydata = timestamps;
                h = heatmap(xdata, ydata, cdata);
                hs = struct(h);
                hs.XAxis.TickLabelRotation = Settings.TickLabelRotation;
                if Settings.PlotTitles
                    h.Title = ["Normalized Log Magnitude Heatmap - " + exp, ...
                               "(Normalized against " + baseline + ")", ...
                               "Colormap: Normalized Signal Strength (dBm)"];
                end
                h.XLabel = "Frequency (GHz)";
                h.YLabel = "Time (s)";
                h.GridVisible = false;
                h.Colormap = turbo;
                setupLabelTicks(h, xdata, "X");
                setupLabelTicks(h, ydata, "Y");
                caxis(Settings.NormalizedHeatMapMLOGCLimit);
                a = annotation('textarrow', [0.975,0.975], [0.5,0.5], ...
                               'String', 'Normalized Signal Strength (dBm)', ...
                               'HeadStyle', 'none', 'LineStyle', 'none', ...
                               'HorizontalAlignment', 'center', ...
                               'TextRotation', 90, ...
                               'FontSize', Settings.AxisFontSize);
                set(gca, "FontSize", Settings.AxisFontSize);
                set(gcf, "Position", Settings.PlotPosition);
                
                path = fullfile(outputDir, exp, "heatmap-norm-MLOG");
                savefig(path);
                exportgraphics(h, path + ".png", 'Resolution', 500);
                delete(a);
            elseif strcmp(traceData.traceFormat, "PHAS")
                % Parse trace data as Phase
                disp("PHAS:")

                cdata = wrapToPi(flip(normalizedData, 1));
                timestamps = flip(linspace(0, expData.totalTime, size(normalizedData, 1)));
    
                xdata = expData.frequency / power(10, 9);
                ydata = timestamps;
                h = heatmap(xdata, ydata, cdata);
                hs = struct(h);
                hs.XAxis.TickLabelRotation = Settings.TickLabelRotation;
                if Settings.PlotTitles
                    h.Title = ["Normalized Phase Heatmap - " + exp, ...
                               "(Normalized against " + baseline + ")", ...
                               "Colormap: Normalized Phase (rad)"];
                end
                h.XLabel = "Frequency (GHz)";
                h.YLabel = "Time (s)";
                h.GridVisible = false;
                h.Colormap = parula;
                setupLabelTicks(h, xdata, "X");
                setupLabelTicks(h, ydata, "Y");
                caxis(Settings.NormalizedHeatMapPHASCLimit);
                a = annotation('textarrow', [0.975,0.975], [0.5,0.5], ...
                               'String', 'Normalized Phase (rad)', ...
                               'HeadStyle', 'none', 'LineStyle', 'none', ...
                               'HorizontalAlignment', 'center', ...
                               'TextRotation', 90, ...
                               'FontSize', Settings.AxisFontSize);
                set(gca, "FontSize", Settings.AxisFontSize);
                set(gcf, "Position", Settings.PlotPosition);
                
                path = fullfile(outputDir, exp, "heatmap-norm-PHAS");
                savefig(path);
                exportgraphics(h, path + ".png", 'Resolution', 500);
                delete(a);
            end

            disp("Max: " + string(max(max(cdata))))
            disp("Min: " + string(min(min(cdata))))
        end
    end

    % Plot normalized heatmaps (grouped)
    if Settings.PlotNormalizedHeatMapGrouped && baseline ~= ""
        disp("Normalized and grouped heatmap:")
        for traceInd = expData.enabledTraces
            traceData = expData.(strcat("trace", string(traceInd)));
            normalizedData = traceData.normalizedData;

            if strcmp(traceData.traceFormat, "PHAS")
                normalizedData = wrapToPi(normalizedData);
            end

            groupedData = groupData(normalizedData, ...
                                    Settings.NormalizedGroupedHeatMapYBatchSize, ...
                                    Settings.NormalizedGroupedHeatMapXBatchSize, ...
                                    @mean);
    
            if strcmp(traceData.traceFormat, "MLOG")
                % Parse trace data as Log Magnitude
                disp("MLOG:")
                cdata = flip(groupedData, 1);
                printExtremes(cdata);
                timestamps = flip(linspace(0, expData.totalTime, size(groupedData, 1)));
                
                xdata = linspace(min(expData.frequency), max(expData.frequency), size(groupedData, 2)) / power(10, 9);
                ydata = timestamps;
                h = heatmap(xdata, ydata, cdata);
                hs = struct(h);
                hs.XAxis.TickLabelRotation = Settings.TickLabelRotation;
                if Settings.PlotTitles
                    h.Title = ["Normalized and Grouped Log Magnitude Heatmap - " + exp, ...
                               "(Normalized against " + baseline + ")", ...
                               "(Group size: x = " + string(Settings.NormalizedGroupedHeatMapXBatchSize) + ...
                               ", y = " + string(Settings.NormalizedGroupedHeatMapYBatchSize) + ")", ...
                               "Colormap: Normalized Signal Strength (dBm)"];
                end
                h.XLabel = "Frequency (GHz)";
                h.YLabel = "Time (s)";
                h.GridVisible = false;
                h.Colormap = turbo(Settings.NormalizedGroupedHeatMapMLOGColors);
                setupLabelTicks(h, xdata, "X");
                setupLabelTicks(h, ydata, "Y");
                caxis(Settings.NormalizedHeatMapMLOGCLimit);
                a = annotation('textarrow', [0.975,0.975], [0.5,0.5], ...
                               'String', 'Normalized Signal Strength (dBm)', ...
                               'HeadStyle', 'none', 'LineStyle', 'none', ...
                               'HorizontalAlignment', 'center', ...
                               'TextRotation', 90, ...
                               'FontSize', Settings.AxisFontSize);
                set(gca, "FontSize", Settings.AxisFontSize);
                set(gcf, "Position", Settings.PlotPosition);
                
                path = fullfile(outputDir, exp, "heatmap-norm-grouped-MLOG");
                savefig(path);
                exportgraphics(h, path + ".png", 'Resolution', 500);
                delete(a);
            elseif strcmp(traceData.traceFormat, "PHAS")
                % Parse trace data as Phase
                disp("PHAS:")
                cdata = flip(groupedData, 1);
                printExtremes(cdata);
                timestamps = flip(linspace(0, expData.totalTime, size(groupedData, 1)));
    
                xdata = linspace(min(expData.frequency), max(expData.frequency), size(groupedData, 2)) / power(10, 9);
                ydata = timestamps;
                h = heatmap(xdata, ydata, cdata);
                hs = struct(h);
                hs.XAxis.TickLabelRotation = Settings.TickLabelRotation;
                if Settings.PlotTitles
                    h.Title = ["Normalized and Grouped Phase Heatmap - " + exp, ...
                               "(Normalized against " + baseline + ")", ...
                               "(Group size: x = " + string(Settings.NormalizedGroupedHeatMapXBatchSize) + ...
                               ", y = " + string(Settings.NormalizedGroupedHeatMapYBatchSize) + ")", ...
                               "Colormap: Normalized Phase (rad)"];
                end
                h.XLabel = "Frequency (GHz)";
                h.YLabel = "Time (s)";
                h.GridVisible = false;
                h.Colormap = parula(Settings.NormalizedGroupedHeatMapPHASColors);
                setupLabelTicks(h, xdata, "X");
                setupLabelTicks(h, ydata, "Y");
                caxis(Settings.NormalizedHeatMapPHASCLimit);
                a = annotation('textarrow', [0.975,0.975], [0.5,0.5], ...
                               'String', 'Normalized Phase (rad)', ...
                               'HeadStyle', 'none', 'LineStyle', 'none', ...
                               'HorizontalAlignment', 'center', ...
                               'TextRotation', 90, ...
                               'FontSize', Settings.AxisFontSize);
                set(gca, "FontSize", Settings.AxisFontSize);
                set(gcf, "Position", Settings.PlotPosition);
                
                path = fullfile(outputDir, exp, "heatmap-norm-grouped-PHAS");
                savefig(path);
                exportgraphics(h, path + ".png", 'Resolution', 500);
                delete(a);
            end

            % Plot CI for grouped data
            if Settings.PlotNormalizedHeatMapGroupedCI
                [maxVal, maxInd] = max(cdata, [], "all");
                [minVal, minInd] = min(cdata, [], "all");
                CIData = groupData(normalizedData, ...
                                   Settings.NormalizedGroupedHeatMapYBatchSize, ...
                                   Settings.NormalizedGroupedHeatMapXBatchSize, ...
                                   @CISize1D);

                cdata = flip(CIData, 1);
                fprintf("Max Value CI: [%f, %f]\n", ...
                    maxVal - cdata(maxInd), ...
                    maxVal + cdata(maxInd));
                fprintf("Min Value CI: [%f, %f]\n", ...
                    minVal - cdata(minInd), ...
                    minVal + cdata(minInd));

                timestamps = flip(linspace(0, expData.totalTime, size(groupedData, 1)));
                
                xdata = linspace(min(expData.frequency), max(expData.frequency), size(groupedData, 2)) / power(10, 9);
                ydata = timestamps;
                h = heatmap(xdata, ydata, cdata);
                hs = struct(h);
                hs.XAxis.TickLabelRotation = Settings.TickLabelRotation;
                if Settings.PlotTitles
                    h.Title = ["95% CI of Normalized and Grouped " + traceData.traceFormat + " - " + exp, ...
                               "(Normalized against " + baseline + ")", ...
                               "(Group size: x = " + string(Settings.NormalizedGroupedHeatMapXBatchSize) + ...
                               ", y = " + string(Settings.NormalizedGroupedHeatMapYBatchSize) + ")"];
                end
                h.XLabel = "Frequency (GHz)";
                h.YLabel = "Time (s)";
                h.GridVisible = false;
                h.Colormap = cool(Settings.NormalizedGroupedHeatMapMLOGColors);
                setupLabelTicks(h, xdata, "X");
                setupLabelTicks(h, ydata, "Y");
                a = annotation('textarrow', [0.975,0.975], [0.5,0.5], ...
                               'String', '95% CI +/-', ...
                               'HeadStyle', 'none', 'LineStyle', 'none', ...
                               'HorizontalAlignment', 'center', ...
                               'TextRotation', 90, ...
                               'FontSize', Settings.AxisFontSize);
                set(gca, "FontSize", Settings.AxisFontSize);
                set(gcf, "Position", Settings.PlotPosition);
                
                path = fullfile(outputDir, exp, "heatmap-norm-grouped-CI-" + traceData.traceFormat);
                savefig(path);
                exportgraphics(h, path + ".png", 'Resolution', 500);
                delete(a);
            end

            disp("Max: " + string(max(max(cdata))))
            disp("Min: " + string(min(min(cdata))))
        end
    end

    % Plot averaged frames over time
    if Settings.PlotAveragedFramesOverTime && baseline ~= ""
        for traceInd = expData.enabledTraces
            baselineTraceData = baselineData.(strcat("trace", string(traceInd)));
            traceData = expData.(strcat("trace", string(traceInd)));
            traceFormat = traceData.traceFormat;

            if (traceFormat ~= baselineTraceData.traceFormat)
                disp("ERROR: inconsistent trace format with baseline");
                return;
            end

            baselineMean = mean(baselineTraceData.cdata, 1);
            expMean = mean(traceData.cdata, 1);

            [baselineCILow, baselineCIHigh] = CIOffset(baselineTraceData.cdata, 1);
            baselineFill = fill([baselineData.frequency flip(baselineData.frequency)], ...
                                [(baselineCILow + baselineMean) flip(baselineCIHigh + baselineMean)], ...
                                'blue', "DisplayName", baseline + " 95% CI");
            baselineFill.FaceColor = [0.8 0.8 1];
            baselineFill.EdgeColor = 'none';

            hold on

            [expCILow, expCIHigh] = CIOffset(traceData.cdata, 1);
            expFill = fill([expData.frequency flip(expData.frequency)], ...
                           [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                           'red', "DisplayName", exp + " 95% CI");
            expFill.FaceColor = [1 0.8 0.8];
            expFill.EdgeColor = 'none';

            plot(baselineData.frequency, baselineMean, 'b-', "DisplayName", baseline + " Mean");
            plot(expData.frequency, expMean, 'r-', "DisplayName", exp + " Mean");

            if strcmp(traceFormat, "PHAS") == 1
                legend("Location", "northeast");
            else
                legend("Location", "southeast");
            end

            legend show

            plotTitle = "";
            xlabel("Frequency (Hz)", "FontSize", Settings.AxisFontSize);
            [ylimMin, ylimMax] = getLimits(expMean, Settings.AxisLimitRounding);
            if strcmp(traceFormat, 'MLOG') == 1
                plotTitle = plotTitle + 'Log Magnitude';
                ylabel("Magnitude (dB)", "FontSize", Settings.AxisFontSize);
                ylim([ylimMin ylimMax]);
            elseif strcmp(traceFormat, 'MLIN') == 1
                plotTitle = plotTitle + 'Linear Magnitude';
                ylabel("Magnitude (mU)", "FontSize", Settings.AxisFontSize);
                ylim([ylimMin ylimMax]);
            elseif strcmp(traceFormat, 'PHAS') == 1
                plotTitle = plotTitle + 'Phase';
                ylabel("Phase (rad)", "FontSize", Settings.AxisFontSize);
            elseif strcmp(traceFormat, 'PPH') == 1
                plotTitle = plotTitle + 'Positive Phase';
                ylabel("Phase (rad)", "FontSize", Settings.AxisFontSize);
            end
            plotTitle = plotTitle + " Average over Time - " + exp;
            if Settings.PlotTitles
                title(plotTitle);
            end
            set(gca, "FontSize", Settings.AxisFontSize);
            set(gcf, "Position", Settings.PlotPosition);

            hold off

            path = fullfile(outputDir, exp, "avg-frames-time-" + traceFormat);
            savefig(path);
            exportgraphics(gcf, path + ".png", 'Resolution', 500);
        end
    end

    % Plot averaged frames over frequency
    if Settings.PlotAveragedFramesOverFreq && baseline ~= ""
        for traceInd = expData.enabledTraces
            traceData = expData.(strcat("trace", string(traceInd)));
            traceFormat = traceData.traceFormat;

            if strcmp(traceFormat, "PHAS") || strcmp(traceFormat, "PPH")
                continue
            end

            timestamps = linspace(0, expData.totalTime, size(traceData.cdata, 1));
            expMean = mean(traceData.cdata, 2).';

            [expCILow, expCIHigh] = CIOffset(traceData.cdata, 2);
            expFill = fill([timestamps flip(timestamps)], ...
                           [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                           'red', "DisplayName", "95% CI");
            expFill.FaceColor = [1 0.8 0.8];
            expFill.EdgeColor = 'none';

            hold on

            plot(timestamps, expMean, 'r-', "DisplayName", "Mean");

            if strcmp(traceFormat, "PHAS") == 1
                legend("Location", "northeast");
            else
                legend("Location", "southeast");
            end

            legend show

            plotTitle = "";
            xlabel("Time (s)", "FontSize", Settings.AxisFontSize);
            [ylimMin, ylimMax] = getLimits(expMean, Settings.AxisLimitRounding);
            if strcmp(traceFormat, 'MLOG') == 1
                plotTitle = plotTitle + 'Log Magnitude';
                ylabel("Magnitude (dB)", "FontSize", Settings.AxisFontSize);
                ylim([ylimMin ylimMax]);
            elseif strcmp(traceFormat, 'MLIN') == 1
                plotTitle = plotTitle + 'Linear Magnitude';
                ylabel("Magnitude (mU)", "FontSize", Settings.AxisFontSize);
                ylim([ylimMin ylimMax]);
            elseif strcmp(traceFormat, 'PHAS') == 1
                plotTitle = plotTitle + 'Phase';
                ylabel("Phase (rad)", "FontSize", Settings.AxisFontSize);
            elseif strcmp(traceFormat, 'PPH') == 1
                plotTitle = plotTitle + 'Positive Phase';
                ylabel("Phase (rad)", "FontSize", Settings.AxisFontSize);
            end
            plotTitle = plotTitle + " Average over Freq - " + exp;
            if Settings.PlotTitles
                title(plotTitle);
            end
            set(gca, "FontSize", Settings.AxisFontSize);
            set(gcf, "Position", Settings.PlotPosition);

            hold off

            path = fullfile(outputDir, exp, "avg-frames-freq-" + traceFormat);
            savefig(path);
            exportgraphics(gcf, path + ".png", 'Resolution', 500);
        end
    end

    % Plot averaged frames over selected frequency
    if Settings.PlotAveragedFramesOverNarrowFreq && baseline ~= ""
        for traceInd = expData.enabledTraces
            traceData = expData.(strcat("trace", string(traceInd)));
            traceFormat = traceData.traceFormat;
            normalizedData = traceData.normalizedData;

            if strcmp(traceFormat, "PHAS") || strcmp(traceFormat, "PPH")
                continue
            end
            
            freqInd = find(expData.frequency >= Settings.AveragedFramesFreqStart & ...
                           expData.frequency <= Settings.AveragedFramesFreqEnd);

            timestamps = linspace(0, expData.totalTime - Settings.AveragedFramesBatchSize / FPS, ...
                                  size(normalizedData, 1));
            expMean = mean(normalizedData(:, freqInd), 2).';
            [ylimMin, ylimMax] = getLimits(expMean, Settings.AxisLimitRounding);

            if (Settings.AveragedFramesFreqStart2 == 0 || Settings.AveragedFramesOverNarrowFreqCI)
                [expCILow, expCIHigh] = CIOffset(normalizedData(:, freqInd), 2);
                if Settings.AveragedFramesFreqStart2 == 0
                    fillName = Settings.FreqGroupName + " 95% CI";
                    expFill = fill([timestamps flip(timestamps)], ...
                                   [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                                   'red', "DisplayName", fillName);
                else
                    expFill = fill([timestamps flip(timestamps)], ...
                                   [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                                   'red', "HandleVisibility", 'off');
                end
                expFill.FaceColor = [1 0.8 0.8];
                expFill.FaceAlpha = Settings.FillAlpha;
                expFill.EdgeColor = 'none';
            end

            hold on

            if Settings.AveragedFramesFreqStart2 == 0
                lineName = Settings.FreqGroupName + " Mean";
            else
                lineName = Settings.FreqGroupName;
            end
            plot(timestamps, expMean, 'r-', "DisplayName", lineName, "LineWidth", Settings.LineWidth);

            if Settings.AveragedFramesFreqStart2 ~= 0
                freqInd = find(expData.frequency >= Settings.AveragedFramesFreqStart2 & ...
                               expData.frequency <= Settings.AveragedFramesFreqEnd2);

                expMean = mean(normalizedData(:, freqInd), 2).';
                [yMin, yMax] = getLimits(expMean, Settings.AxisLimitRounding);
                ylimMin = min(ylimMin, yMin);
                ylimMax = max(ylimMax, yMax);

                if Settings.AveragedFramesOverNarrowFreqCI
                    [expCILow, expCIHigh] = CIOffset(normalizedData(:, freqInd), 2);
                    expFill = fill([timestamps flip(timestamps)], ...
                                   [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                                   'green', "HandleVisibility", 'off');
                    expFill.FaceColor = [0.8 1 0.8];
                    expFill.FaceAlpha = Settings.FillAlpha;
                    expFill.EdgeColor = 'none';
                end

                lineName = Settings.FreqGroupName2;
                plot(timestamps, expMean, 'g-', "DisplayName", lineName, "LineWidth", Settings.LineWidth);
            end

            if Settings.AveragedFramesFreqStart3 ~= 0
                freqInd = find(expData.frequency >= Settings.AveragedFramesFreqStart3 & ...
                               expData.frequency <= Settings.AveragedFramesFreqEnd3);

                expMean = mean(normalizedData(:, freqInd), 2).';
                [yMin, yMax] = getLimits(expMean, Settings.AxisLimitRounding);
                ylimMin = min(ylimMin, yMin);
                ylimMax = max(ylimMax, yMax);

                if Settings.AveragedFramesOverNarrowFreqCI
                    [expCILow, expCIHigh] = CIOffset(normalizedData(:, freqInd), 2);
                    expFill = fill([timestamps flip(timestamps)], ...
                                   [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                                   'blue', "HandleVisibility", 'off');
                    expFill.FaceColor = [0.8 0.8 1];
                    expFill.FaceAlpha = Settings.FillAlpha;
                    expFill.EdgeColor = 'none';
                end

                lineName = Settings.FreqGroupName3;
                plot(timestamps, expMean, 'b-', "DisplayName", lineName, "LineWidth", Settings.LineWidth);
            end

            if strcmp(traceFormat, "PHAS") == 1
                legend("Location", "northeast");
            else
                legend("Location", "southwest");
            end

            legend show

            plotTitle = "";
            xlabel("Time (s)", "FontSize", Settings.AxisFontSize);
            if strcmp(traceFormat, 'MLOG') == 1
                plotTitle = plotTitle + 'Log Magnitude';
                ylabel("Normalized Signal Strength (dBm)", "FontSize", Settings.AxisFontSize);
                ylim([ylimMin ylimMax]);
            elseif strcmp(traceFormat, 'MLIN') == 1
                plotTitle = plotTitle + 'Linear Magnitude';
                ylabel("Normalized Signal Strength (mU)", "FontSize", Settings.AxisFontSize);
                ylim([ylimMin ylimMax]);
            elseif strcmp(traceFormat, 'PHAS') == 1
                plotTitle = plotTitle + 'Phase';
                ylabel("Normalized Phase (rad)", "FontSize", Settings.AxisFontSize);
            elseif strcmp(traceFormat, 'PPH') == 1
                plotTitle = plotTitle + 'Positive Phase';
                ylabel("Normalized Phase (rad)", "FontSize", Settings.AxisFontSize);
            end
            startFreqStr = sprintf('%0.3e', Settings.AveragedFramesFreqStart);
            endFreqStr = sprintf('%0.3e', Settings.AveragedFramesFreqEnd);
            plotTitle = [plotTitle + " Average over Freq - " + exp, ...
                         "Freq Range: " + startFreqStr + " - " + endFreqStr];
            if Settings.PlotTitles
                title(plotTitle);
            end
            set(gca, "FontSize", Settings.AxisFontSize);
            set(gcf, "Position", Settings.PlotPosition);

            hold off

            path = fullfile(outputDir, exp, "avg-frames-selected-freq-" + traceFormat);
            savefig(path);
            exportgraphics(gcf, path + ".png", 'Resolution', 500);
        end

        close all
    end

    % Plot averaged frames over frequency (grouped)
    if Settings.PlotAveragedFramesOverFreqGrouped && baseline ~= ""
        for traceInd = expData.enabledTraces
            traceData = expData.(strcat("trace", string(traceInd)));
            traceFormat = traceData.traceFormat;

            if strcmp(traceFormat, "PHAS") || strcmp(traceFormat, "PPH")
                continue
            end

            totalTimestamps = size(traceData.cdata, 1);
            cdata = traceData.cdata(1:totalTimestamps - mod(totalTimestamps, Settings.AveragedFramesBatchSize), :);
            cdataGrouped = reshape(cdata.', ...
                                   size(cdata, 2) * Settings.AveragedFramesBatchSize, ...
                                   size(cdata, 1) / Settings.AveragedFramesBatchSize).';

            expMean = mean(cdataGrouped, 2).';
            timestamps = linspace(0, expData.totalTime, numel(expMean));

            [expCILow, expCIHigh] = CIOffset(cdataGrouped, 2);
            expFill = fill([timestamps flip(timestamps)], ...
                           [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                           'red', "DisplayName", "95% CI");
            expFill.FaceColor = [1 0.8 0.8];
            expFill.EdgeColor = 'none';

            hold on

            plot(timestamps, expMean, 'r-', "DisplayName", "Mean");

            if strcmp(traceFormat, "PHAS") == 1
                legend("Location", "northeast");
            else
                legend("Location", "southeast");
            end

            legend show

            plotTitle = "";
            xlabel("Time (s)", "FontSize", Settings.AxisFontSize);
            [ylimMin, ylimMax] = getLimits(mean(cdata, 2), Settings.AxisLimitRounding);
            if strcmp(traceFormat, 'MLOG') == 1
                plotTitle = plotTitle + 'Log Magnitude';
                ylabel("Magnitude (dB)", "FontSize", Settings.AxisFontSize);
                ylim([ylimMin ylimMax]);
            elseif strcmp(traceFormat, 'MLIN') == 1
                plotTitle = plotTitle + 'Linear Magnitude';
                ylabel("Magnitude (mU)", "FontSize", Settings.AxisFontSize);
                ylim([ylimMin ylimMax]);
            elseif strcmp(traceFormat, 'PHAS') == 1
                plotTitle = plotTitle + 'Phase';
                ylabel("Phase (rad)", "FontSize", Settings.AxisFontSize);
            elseif strcmp(traceFormat, 'PPH') == 1
                plotTitle = plotTitle + 'Positive Phase';
                ylabel("Phase (rad)", "FontSize", Settings.AxisFontSize);
            end
            plotTitle = [plotTitle + " Average over Freq - " + exp, ...
                         "(Group size: " + string(Settings.AveragedFramesBatchSize) + ")"];
            if Settings.PlotTitles
                title(plotTitle);
            end
            set(gca, "FontSize", Settings.AxisFontSize);
            set(gcf, "Position", Settings.PlotPosition);

            hold off

            path = fullfile(outputDir, exp, "avg-frames-freq-grouped-" + traceFormat);
            savefig(path);
            exportgraphics(gcf, path + ".png", 'Resolution', 500);
        end
    end

    % Plot averaged frames over selected frequency (grouped)
    if Settings.PlotAveragedFramesOverNarrowFreqGrouped && baseline ~= ""
        for traceInd = expData.enabledTraces
            traceData = expData.(strcat("trace", string(traceInd)));
            traceFormat = traceData.traceFormat;
            normalizedData = traceData.normalizedData;

            if strcmp(traceFormat, "PHAS") || strcmp(traceFormat, "PPH")
                continue
            end
            
            freqInd = find(expData.frequency >= Settings.AveragedFramesFreqStart & ...
                           expData.frequency <= Settings.AveragedFramesFreqEnd);
            totalTimestamps = size(normalizedData, 1);
            cdata = normalizedData(1:totalTimestamps - mod(totalTimestamps, Settings.AveragedFramesBatchSize), freqInd);
            cdataGrouped = reshape(cdata.', ...
                                   size(cdata, 2) * Settings.AveragedFramesBatchSize, ...
                                   size(cdata, 1) / Settings.AveragedFramesBatchSize).';

            expMean = mean(cdataGrouped, 2).';
            [ylimMin, ylimMax] = getLimits(expMean, Settings.AxisLimitRounding);

            baselineMean = expMean(:, 1:Settings.BaselineLength);
            baselineMeanAvg = mean(baselineMean);
            [CILow, CIHigh] = CIOffset(baselineMean, 2);
            fprintf("Baseline Mean: %f [%f, %f]\n", ...
                baselineMeanAvg, baselineMeanAvg + CILow, baselineMeanAvg + CIHigh);

            %dataMean = mean(normalizedData(:, freqInd), 2).';
            %[dataMin, dataMax] = getLimits(dataMean, Settings.AxisLimitRounding);
            %ylimMin = min(ylimMin, dataMin);
            %ylimMax = max(ylimMax, dataMax);
            
            timestamps = linspace(0, expData.totalTime - Settings.AveragedFramesBatchSize / FPS, ...
                                  numel(expMean));

            if (Settings.AveragedFramesFreqStart2 == 0 || Settings.AveragedFramesOverNarrowFreqGroupedCI)
                [expCILow, expCIHigh] = CIOffset(cdataGrouped, 2);
                if Settings.AveragedFramesFreqStart2 == 0
                    fillName = Settings.FreqGroupName + " 95% CI";
                    expFill = fill([timestamps flip(timestamps)], ...
                                   [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                                   'red', "DisplayName", fillName);
                else
                    expFill = fill([timestamps flip(timestamps)], ...
                                   [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                                   'red', "HandleVisibility", 'off');
                end
                expFill.FaceColor = [1 0.8 0.8];
                expFill.FaceAlpha = Settings.FillAlpha;
                expFill.EdgeColor = 'none';
            end

            hold on

            if Settings.AveragedFramesFreqStart2 == 0
                lineName = Settings.FreqGroupName + " Mean";
            else
                lineName = Settings.FreqGroupName;
            end
            plot(timestamps, expMean, 'r-', "DisplayName", lineName, "LineWidth", Settings.LineWidth);

            if Settings.AveragedFramesFreqStart2 ~= 0
                freqInd = find(expData.frequency >= Settings.AveragedFramesFreqStart2 & ...
                               expData.frequency <= Settings.AveragedFramesFreqEnd2);
                totalTimestamps = size(normalizedData, 1);
                cdata = normalizedData(1:totalTimestamps - mod(totalTimestamps, Settings.AveragedFramesBatchSize), freqInd);
                cdataGrouped = reshape(cdata.', ...
                                       size(cdata, 2) * Settings.AveragedFramesBatchSize, ...
                                       size(cdata, 1) / Settings.AveragedFramesBatchSize).';
    
                expMean = mean(cdataGrouped, 2).';
                [yMin, yMax] = getLimits(expMean, Settings.AxisLimitRounding);
                ylimMin = min(ylimMin, yMin);
                ylimMax = max(ylimMax, yMax);
                % disp("Baseline Mean: " + string(mean(expMean(:, 1:Settings.BaselineLength))))

                if Settings.AveragedFramesOverNarrowFreqGroupedCI
                    [expCILow, expCIHigh] = CIOffset(cdataGrouped, 2);
                    expFill = fill([timestamps flip(timestamps)], ...
                                   [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                                   'green', "HandleVisibility", 'off');
                    expFill.FaceColor = [0.8 1 0.8];
                    expFill.FaceAlpha = Settings.FillAlpha;
                    expFill.EdgeColor = 'none';
                end

                lineName = Settings.FreqGroupName2;
                plot(timestamps, expMean, 'g-', "DisplayName", lineName, "LineWidth", Settings.LineWidth);
            end

            if Settings.AveragedFramesFreqStart3 ~= 0
                freqInd = find(expData.frequency >= Settings.AveragedFramesFreqStart3 & ...
                               expData.frequency <= Settings.AveragedFramesFreqEnd3);
                totalTimestamps = size(normalizedData, 1);
                cdata = normalizedData(1:totalTimestamps - mod(totalTimestamps, Settings.AveragedFramesBatchSize), freqInd);
                cdataGrouped = reshape(cdata.', ...
                                       size(cdata, 2) * Settings.AveragedFramesBatchSize, ...
                                       size(cdata, 1) / Settings.AveragedFramesBatchSize).';
    
                expMean = mean(cdataGrouped, 2).';
                [yMin, yMax] = getLimits(expMean, Settings.AxisLimitRounding);
                ylimMin = min(ylimMin, yMin);
                ylimMax = max(ylimMax, yMax);
                % disp("Baseline Mean: " + string(mean(expMean(:, 1:Settings.BaselineLength))))

                if Settings.AveragedFramesOverNarrowFreqGroupedCI
                    [expCILow, expCIHigh] = CIOffset(cdataGrouped, 2);
                    expFill = fill([timestamps flip(timestamps)], ...
                                   [(expCILow + expMean) flip(expCIHigh + expMean)], ...
                                   'blue', "HandleVisibility", 'off');
                    expFill.FaceColor = [0.8 0.8 1];
                    expFill.FaceAlpha = Settings.FillAlpha;
                    expFill.EdgeColor = 'none';
                end

                lineName = Settings.FreqGroupName3;
                plot(timestamps, expMean, 'b-', "DisplayName", lineName, "LineWidth", Settings.LineWidth);
            end

            if strcmp(traceFormat, "PHAS") == 1
                legend("Location", "northeast");
            else
                legend("Location", "southwest");
            end

            legend show

            plotTitle = "";
            xlabel("Time (s)", "FontSize", Settings.AxisFontSize);
            if strcmp(traceFormat, 'MLOG') == 1
                plotTitle = plotTitle + 'Log Magnitude';
                ylabel("Normalized Signal Strength (dBm)", "FontSize", Settings.AxisFontSize);
                ylim([ylimMin ylimMax]);
            elseif strcmp(traceFormat, 'MLIN') == 1
                plotTitle = plotTitle + 'Linear Magnitude';
                ylabel("Normalized Signal Strength (mU)", "FontSize", Settings.AxisFontSize);
                ylim([ylimMin ylimMax]);
            elseif strcmp(traceFormat, 'PHAS') == 1
                plotTitle = plotTitle + 'Phase';
                ylabel("Normalized Phase (rad)", "FontSize", Settings.AxisFontSize);
            elseif strcmp(traceFormat, 'PPH') == 1
                plotTitle = plotTitle + 'Positive Phase';
                ylabel("Normalized Phase (rad)", "FontSize", Settings.AxisFontSize);
            end
            startFreqStr = sprintf('%0.3e', Settings.AveragedFramesFreqStart);
            endFreqStr = sprintf('%0.3e', Settings.AveragedFramesFreqEnd);
            plotTitle = [plotTitle + " Average over Freq - " + exp, ...
                         "Freq Range: " + startFreqStr + " - " + endFreqStr, ...
                         "(Group size: " + string(Settings.AveragedFramesBatchSize) + ")"];
            if Settings.PlotTitles
                title(plotTitle);
            end
            set(gca, "FontSize", Settings.AxisFontSize);
            set(gcf, "Position", Settings.PlotPosition);

            hold off

            path = fullfile(outputDir, exp, "avg-frames-selected-freq-grouped-" + traceFormat);
            savefig(path);
            exportgraphics(gcf, path + ".png", 'Resolution', 500);
        end

        close all
    end

    % Plot frames
    if Settings.PlotFrames
        for secInd = 1:expData.totalTime
            frameInd = (secInd - 1) * FPS + 1;
            for traceInd = expData.enabledTraces
                traceData = expData.(strcat("trace", string(traceInd)));
                traceFormat = traceData.traceFormat;
                subplot(totalTraces, 1, traceInd);
                cdata = traceData.cdata(frameInd, :);
                plot(expData.frequency, cdata);
            
                plotTitle = "";
                xlabel("Frequency (Hz)", "FontSize", Settings.AxisFontSize);
                if strcmp(traceFormat, 'MLOG') == 1
                    plotTitle = plotTitle + 'Log Magnitude';
                    ylabel("Magnitude (dB)", "FontSize", Settings.AxisFontSize);
                    ylim([limitMin(traceInd) limitMax(traceInd)]);
                elseif strcmp(traceFormat, 'MLIN') == 1
                    plotTitle = plotTitle + 'Linear Magnitude';
                    ylabel("Magnitude (mU)", "FontSize", Settings.AxisFontSize);
                    ylim([limitMin(traceInd) limitMax(traceInd)]);
                elseif strcmp(traceFormat, 'PHAS') == 1
                    plotTitle = plotTitle + 'Phase';
                    ylabel("Phase (rad)", "FontSize", Settings.AxisFontSize);
                elseif strcmp(traceFormat, 'PPH') == 1
                    plotTitle = plotTitle + 'Positive Phase';
                    ylabel("Phase (rad)", "FontSize", Settings.AxisFontSize);
                end
                plotTitle = plotTitle + " - " + exp;
                title([plotTitle, "sec " + string(secInd)]);
            end
            set(gca, "FontSize", Settings.AxisFontSize);
            set(gcf, "Position", Settings.PlotPosition);
    
            path = fullfile(outputDir, exp, "frames", "frame-" + string(secInd));
            exportgraphics(gcf, path + ".png", 'Resolution', 500);
        end
    end

    close all
end


function lastTick = roundToLastTick(n, interval)
    multiplier = 1;
    while mod(interval, 1) ~= 0
        interval = interval * 10;
        n = n * 10;
        multiplier = multiplier * 10;
    end
    lastTick = floor(n - mod(n, interval)) / multiplier;
end


function setupLabelTicks(h, data, axis)
    labelName = axis + "DisplayLabels";
    h.(labelName)(1:length(data)) = {''};
    h.(labelName)(1) = {string(data(1))};
    h.(labelName)(end) = {string(data(end))};
    
    dataRange = max(data) - min(data);
    if strcmp(axis, "X") == 1
        indRange = 2:length(data)-1;
        if dataRange <= 0.1
            interval = 0.02;
        elseif dataRange <= 1
            interval = 0.1;
        elseif dataRange <= 10
            interval = 1;
        else
            interval = 10;
        end
    else
        indRange = length(data)-1:-1:2;
        if dataRange <= 60
            interval = 10;
        else
            interval = 60;
        end
    end

    lastTick = roundToLastTick(data(1), interval);
    minTick = min(data(1), data(end));
    maxTick = max(data(1), data(end));

    for labelInd = indRange
        currTick = roundToLastTick(data(labelInd), interval);
        if (currTick ~= lastTick && currTick > minTick && currTick < maxTick)
            h.(labelName)(labelInd) = {string(currTick)};
            lastTick = currTick;
        end
    end
end


% Calculate confidence interval for each column
function [CILow, CIHigh] = CIOffset(cdata, dim)
    N = size(cdata, dim);
    SEM = std(cdata, 0, dim) / sqrt(N);
    if dim == 2
        SEM = SEM.';
    end
    tsLow = tinv(0.025, N - 1);
    tsHigh = tinv(0.975, N - 1);
    CILow = tsLow * SEM;
    CIHigh = tsHigh * SEM;
end


% Calculate the size of confidence interval for 1D data
function CISize = CISize1D(cdata)
    [CILow, CIHigh] = CIOffset(cdata, 1);
    CISize = (CIHigh - CILow) / 2;
end


% Split vector into groups of size m and apply func to each group
function groupedData = groupData1D(data, m, func)
    groupedData = accumarray(ceil((1:numel(data)) / m)', data(:), [], func);
end


% Split 2D data into groups with dimension m x n and apply func to each group
function groupedData = groupData(data, m, n, func)
    newSize = ceil([size(data, 1) / m, size(data, 2) / n]);

    groupedDataRows = ones(size(data, 1), newSize(2));
    for rowInd = 1:size(data, 1)
        groupedDataRows(rowInd, :) = groupData1D(data(rowInd, :)', n, func)';
    end

    groupedData = ones(newSize);
    for colInd = 1:newSize(2)
        groupedData(:, colInd) = groupData1D(groupedDataRows(:, colInd), m, func);
    end
end


% Get limits of data by rounding min and max values to the next rounding
function [limitMin, limitMax] = getLimits(data, rounding)
    limitMin = floor(min(data) / rounding) * rounding;
    limitMax = ceil(max(data) / rounding) * rounding;
end


% Get limits of 2D data by rounding min and max values to the next rounding
function [limitMin, limitMax] = getLimits2D(data, rounding)
    limitMin = floor(min(min(data)) / rounding) * rounding;
    limitMax = ceil(max(max(data)) / rounding) * rounding;
end

% Print the extreme values in data and their corresponding indices
function printExtremes(data)
    [maxVal, maxInd] = max(data, [], "all");
    [minVal, minInd] = min(data, [], "all");
    [maxRow, maxCol] = ind2sub(size(data), maxInd);
    [minRow, minCol] = ind2sub(size(data), minInd);
    fprintf("Max Value: %f (%d, %d)\n", maxVal, maxCol, maxRow);
    fprintf("Min Value: %f (%d, %d)\n", minVal, minCol, minRow);
end
