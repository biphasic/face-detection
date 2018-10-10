classdef Subject < handle
    properties
        Name
        Recordings
        CorrelationThreshold
        Modelblink
        AmplitudeScale
        BlinkLength
    end
        
    methods
        function obj = Subject(name)
            obj.Name = name;
            obj.CorrelationThreshold = 0.88;
            obj.Modelblink = Modelblink();
            obj.BlinkLength = 300000;
        end
        
        function obj = addrecording(obj, number, eventStream, isTrainingRecording)
            obj.Recordings{1,number} = Recording(number, eventStream, isTrainingRecording, obj);
        end
        
        function index = gettrainingrecordingindex(obj)
            for index = 1:numel(obj.Recordings)
                if ~isempty(obj.Recordings{index}) && obj.Recordings{index}.IsTrainingRecording
                    break
                end
            end
        end
        
        function recording = gettrainingrecording(obj)
            recording = obj.Recordings{obj.gettrainingrecordingindex};
        end
        
        function calculateallcorrelations(obj)
            for r = 1:numel(obj.Recordings)
                if ~isempty(obj.Recordings{r})
                    disp(['Subject: ', obj.Name, ', recording no: ', num2str(r)])
                    obj.Recordings{r}.calculatecorrelation();
                end
            end
        end
        
        function ploteyeactivitiesfortraining(obj)
            rec = obj.gettrainingrecording;
            locs = rec.getannotatedlocations;
            figure
            for l = 1:numel(locs)
                rec.(locs{l}).plotactivity(numel(locs), 1, l, locs{l})
            end
        end
        
        function plotallcorrelations(obj)
            if isempty(obj.gettrainingrecording.EventstreamGrid1)
                error('Run correlation first')
            else
                figure
                for r = 1:numel(obj.Recordings)
                    if ~isempty(obj.Recordings{r})
                        ax = subplot(1,length(obj.Recordings), r);
                        obj.Recordings{r}.plotcorrelation(ax);
                    end
                end
            end
        end
        
        function adjustblinkmodel(obj)
            figure
            hold on
            [blinksOn, blinksOff] = obj.gettrainingrecording.getallblinks();
            fields = fieldnames(blinksOn);
            for j = 1:length(fields)
                for i = 1:size(blinksOn.(fields{j}),1)
                    a = plot(blinksOn.(fields{j})(i,:));
                    [xcOn, lagOn] = xcorr(blinksOn.(fields{j})(1,:), blinksOn.(fields{j})(i,:));
                    [~, indexOn] = max(abs(xcOn));
                    lagDiffOn = lagOn(indexOn);
                    [xcOff, lagOff] = xcorr(blinksOff.(fields{j})(1,:), blinksOff.(fields{j})(i,:));
                    [~, indexOff] = max(abs(xcOff));
                    lagDiffOff = lagOff(indexOff);
                    lagDiff = 0.6*lagDiffOn + 0.4*lagDiffOff;
                    if abs(lagDiff) > 1 %resembles accuracy of lagdiff * 100us
                        timestamp = obj.gettrainingrecording.(fields{j}).Times(i)-lagDiff*100;
                        disp(['suggested timestamp for blink ', int2str(i), ' at ', fields{j}, ' is: ', int2str(timestamp)])
                    end
                    a.Color = 'blue';
                    b = plot(blinksOff.(fields{j})(i,:));
                    b.Color = 'red';
                end
                [averageOnFirst, averageOffFirst] = obj.gettrainingrecording.(fields{1}).getaverages();
                [averageOn, averageOff] = obj.gettrainingrecording.(fields{j}).getaverages();
                [xcOn, lagOn] = xcorr(averageOnFirst, averageOn);
                [~, indexOn] = max(abs(xcOn));
                lagDiffOn = lagOn(indexOn);
                [xcOff, lagOff] = xcorr(averageOffFirst, averageOff);
                [~, indexOff] = max(abs(xcOff));
                lagDiffOff = lagOff(indexOff);
                lagDiff = (lagDiffOn + lagDiffOff)/2;
                if abs(lagDiff) > 1
                    disp(['lag between ', fields{1}, ' and ', fields{j}, ' is ', int2str(lagDiff*100), ' us'])
                end
            end
        end
        
        function plotblinkmodel(obj, varargin)
            if isempty(obj.gettrainingrecording.getannotatedlocations())
                error('Blinks annotated')
            end
            if nargin > 1
                ax = varargin{1};
            else
                figure;
                ax = gca;
            end
             %plot both average and variance for ON and OFF
            title(ax, obj.Name)
            ax = shadedErrorBar(1:length(obj.Modelblink.AverageOn), obj.Modelblink.AverageOn, obj.Modelblink.VarianceOn, 'lineprops', '-b');
            ax.mainLine.LineWidth = 3;
            ax = shadedErrorBar(1:length(obj.Modelblink.AverageOff), obj.Modelblink.AverageOff, obj.Modelblink.VarianceOff, 'lineprops', '-r');
            ax.mainLine.LineWidth = 3;
            ylim([0 inf])
        end
    end
    
end