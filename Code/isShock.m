function [shock, Amax] = isShock(acceleration,threshold,interval,Fs)

% shock → Indicates a shock in the acceleration data (boolean)
% Amax → Maximum acceleration in the samples (m/s2)
% acceleration → Acceleration magnitude time vector (m/s2)
% threshold → Acceleration above this value will be considered as shocks (m/s2)
% interval → Interval used in the shock search (s)
% Fs → Sampling rate (Hz)

Amax = max(acceleration(end-interval*Fs:end));

if Amax > threshold
    shock = true;
else
    shock = false;
end

end