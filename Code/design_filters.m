% Analysis of data from Matlab-mobile
% Signals are analyzed with the "signal-analyzer" module
% Filters are designed with the "Filters designer" app

clear all; close all; clc;

%% Loads the data
path.data = ["Data/andando.mat"];
path.filter = ["filter/"];
path.code = "Code/";

for field = fieldnames(path)'
    addpath(field{1});
end

% Obtain each field from the data.mat
data = load(path.data);

% POSITION
lat = data.Position.latitude;
lon = data.Position.longitude;
speed = data.Position.speed;
timePosition = timeElapsed(data.Position.Timestamp);

% ACCELERATION
accX = data.Acceleration.X;
accY = data.Acceleration.Y;
accZ = data.Acceleration.Z;
timeAcc = timeElapsed(data.Acceleration.Timestamp);

% ORIENTATION - its included but not considered
% roll = data.Orientation.X;
% pitch = data.Orientation.Y;
% yaw = data.Orientation.Z;
% timeOrientation = timeElapsed(data.Orientation.Timestamp);

% ANGULAR VELOCITY - BODY  AXIS
wx = data.AngularVelocity.X;
wy = data.AngularVelocity.Y;
wz = data.AngularVelocity.Z;
timeW = timeElapsed(data.AngularVelocity.Timestamp);

%% DATA VISUALIZATION
fig = figure(); clf; 
subplot(5, 1, 1); hold on
plot(timePosition, speed);
legend('speed')

subplot(5, 1, 2); hold on
plot(timePosition, lat);
plot(timePosition, lon);
legend('lat', 'lon');

subplot(5, 1, 3); hold on
plot(timeAcc, accX);
plot(timeAcc, accY);
plot(timeAcc, accZ);
legend('accX', 'accY', 'accZ')

% subplot(5, 1, 4); hold on
% plot(timeOrientation, roll);
% plot(timeOrientation, pitch);
% plot(timeOrientation, yaw);
% legend('roll', 'pitch', 'yaw')

subplot(5, 1, 5); hold on
plot(timeW, wx);
plot(timeW, wy);
plot(timeW, wz);
legend('wx', 'wy', 'wz');

%% Test the data with the designed filter. Hd object
acc = accX * 0;
for ii = 1:length(accY)
    acc(ii) = sqrt(accX(ii)^2 + accY(ii)^2 + accZ(ii)^2);
end
acc = acc - mean(acc);
load(strcat(path.filter, "FIR-LS-Acc.mat"));
filt.acc = Hd;
samplingFreq = 100; % Hz
timeFilt = 0.2; % s
nMeasFilt =  ceil(timeFilt / (1 / samplingFreq));

figure(); hold on
% plot(timeAcc, acc, timeAcc, filter(filt.acc, acc), timeAcc, movmean(acc, nMeasFilt)); legend('raw', 'filt-FIR', 'filt-Movmean');
pass = timeAcc > 85;
plot(timeAcc(pass), filter(filt.acc, acc(pass)), '-', 'LineWidth', 1.5); 
hold on
plot(timeAcc(pass), acc(pass), ':', 'LineWidth', 1.5); 
grid minor
xlabel('Time [s]');
ylabel('Acceleration [m/s^2]')
legend('raw', 'filt-FIR');
% plot(timeAcc, acc, '-b', timeAcc, movmean(acc, nMeasFilt), '--r'); legend('raw', 'filt-FIR', 'filt-Movmean');
% save('Filter\FIR-LS-Acc.mat', 'Hd', '-mat');