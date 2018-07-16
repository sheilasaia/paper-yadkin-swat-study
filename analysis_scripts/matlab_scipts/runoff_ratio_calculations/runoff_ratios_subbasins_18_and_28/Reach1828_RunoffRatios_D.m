%% Import data from spreadsheet
% Script for importing data from the following spreadsheet:
%
%    Workbook: Matlab/Analysis/KSuttles_1018/baseline_my.xlsx
%    Worksheet: output
%
% To extend the code for use with different selected data or a different
% spreadsheet, generate a function instead of a script.

% Auto-generated by MATLAB on 2016/10/18 12:16:11

%% Import the data
[~, ~, raw] = xlsread('Matlab/Analysis/Runoff Ratios/baseline_dr.xlsx','output'); % change this filename and path
raw = raw(2:end,[2,4,5,8]);

%% Create output variable
data = reshape([raw{:}],size(raw));

%% Allocate imported array to column variable names
RCHd = data(:,1);
MONd = data(:,2);
YEARd = data(:,3);
FLOW_OUTcms = data(:,4);

%% Clear temporary variables
clearvars data raw;