function state = getState(velocity,model,interval,Fs)

% state → State of the sensor based in its velocity
% velocity → Velocity magnitude time vector (m/s)
% model → Machine Learning model used for prediction
% interval → Interval used for computing the mean of velocity (s)
% Fs → Sampling rate (Hz)

Vmean = mean(velocity(end-interval*Fs:end));
state = char(predict(model,Vmean));

end