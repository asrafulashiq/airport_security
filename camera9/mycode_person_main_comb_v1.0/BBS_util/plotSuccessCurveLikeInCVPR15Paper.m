% draw success curve from paper
resDir ='..\results';
clr = [0,1,0; 1,0,0; 0,0,1; 1,1,0; 1,0,1; 0,1,1; 1,0.5,0; 1,0,0.5];

load(fullfile(resDir,'Final_results_CVPR15_all_methods.mat'));

methods = fields(ROC);

figure(1);clf; 
subplot(1,2,1);
hold on;
for ii = 1:length(methods)
    plot(thROC,ROC.(methods{ii}),'color',clr(ii,:),'linewidth',2);
end
hold off;
legend(methods);
xlabel('threshold');
ylabel('Success');
grid on;
ylim([0,1]);
title('Success using top candidate')

load(fullfile(resDir,'Final_results_CVPR15_all_methods_top7.mat'));
subplot(1,2,2);
hold on;
for ii = 1:length(methods)
    plot(thROC,ROC.(methods{ii}),'color',clr(ii,:),'linewidth',2);
end
hold off;
legend(methods);
xlabel('threshold');
ylabel('Success');
grid on;
ylim([0,1]);
title('Success using 7-top candidates')