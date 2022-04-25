classdef main_class < matlab.System
    % main_class This is the main class of the project. It is designed to get
    % data either in 'stream' mode from a mobile device app or from a .mat
    % file. It then obtains the state ('IDLE', 'WAKING', 'RUNNING', 'CAR'), and checks whether an impact has ocurred
    % or not.

    % Private variables used internally
    properties(Access = private)
        mobile_obj; % object of the mobile device from which data will be streamed
        model_knn; % model of k-nearest neighbors used for the state computation
        time_step = 0.01; % t_step = 1 / acquisition_frequency, s
        interval_acc = 0.01; % window in acceleration used for max calculation, s
        interval_vel = 2; % windows in velocity used for state calculation, s
        threshold_acceleration = 20; % thresholds of acceleration used for step, m/s2
        n_samples_vel; % number of samples used in the velocity window
        n_samples_acc; % number of samples used in the acceleration window
        time; % current time, s
        iter; % current iteration
        velocity; % current obtained velocity, m/s
        acceleration; % current obtained acceleration, m/s^2
        latitude; % º
        longitude; % º
        offline_data;
        ShockBot; % telegram bot
        flag_update; % update data or not
    end

    properties(GetAccess = private, Constant, Nontunable)
        mode = "stream"; % "online"-> data from mobile, "offline" -> data from -mat
        input_file = "andando.mat" % file used for data loading. It requires to contain at least acceleration and velocity
        BotToken = '5171014369:AAGqkyeKK0Zj8EZbPiaH_DrZ_Q7U-b04C9k'; % users bot tokens
        ChatID = '950714104';
    end

    methods(Access = protected)
        function setupImpl(obj)
            % constructor of the class
            % initializes the sampling data
            obj.n_samples_vel = ceil(obj.interval_vel * (1 / obj.time_step));
            obj.velocity = zeros(obj.n_samples_vel, 1);
            obj.n_samples_acc = ceil(obj.interval_acc * (1 / obj.time_step));
            obj.acceleration = zeros(obj.n_samples_acc, 1);

            obj.time = 0;
            obj.iter = 1;

            obj.flag_update = true;
            
            % loads the model of knn from a -mat file
            load('Data/model.mat');
            obj.model_knn = model;

            addpath('Code');
            addpath('Data');
            addpath('Code/telegram_functions');

            obj.ShockBot = telegram_bot(obj.BotToken);

            if obj.isModeOffline()
                load(obj.input_file);
                obj.offline_data.Acceleration = Acceleration;
                obj.offline_data.Position = Position;
            elseif obj.isModeStream()
                % Enables the mobiles to log and stream data
                obj.mobile_obj = mobiledev;
                obj.mobile_obj.SampleRate = 100; %Sets sample rate at which device will acquire the data
                obj.mobile_obj.AngularVelocitySensorEnabled = 1;
                obj.mobile_obj.OrientationSensorEnabled = 1;
                obj.mobile_obj.AccelerationSensorEnabled = 1;
                obj.mobile_obj.PositionSensorEnabled = 1;
                obj.mobile_obj.MagneticSensorEnabled = 1;
                obj.mobile_obj.Logging = 1; % start the transmission of data from all selected sensors
            else
                error('Selected mode: %s not valid', obj.mode);
            end
        end

        function [t, acc, vel, lat, lon, state, shock, Amax] = stepImpl(obj)
            % calculations of each time-step. It updates the velocity and
            % acceleration data, estimates the current state and checks whether
            % an impact has ocurred or not
            obj.time = obj.time + obj.time_step;
            t = obj.time;
            if obj.isModeOffline()
                % for acceleration it is calculated the norm
                accX = obj.offline_data.Acceleration(obj.iter,:).X;
                accY = obj.offline_data.Acceleration(obj.iter,:).Y;
                accZ = obj.offline_data.Acceleration(obj.iter,:).Z;
                acc = [accX, accY, accZ];
                acc = sqrt(sum(acc.^2, 2));

                if obj.iter > length(obj.offline_data.Position.speed)
                    % gets the values from the last time-sep
                    vel = obj.velocity(end);
                    lat = obj.latitude;
                    lon = obj.longitude;
                    obj.flag_update = false;
                else
                    vel = obj.offline_data.Position(obj.iter, :).speed;
                    lat = obj.offline_data.Position(obj.iter, :).latitude;
                    lon = obj.offline_data.Position(obj.iter, :).longitude;
                    obj.flag_update = true;
                end
                
                obj.iter = obj.iter + 1;
                if obj.iter > size(obj.offline_data.Acceleration, 1)
                    warning('End of file reached... iteration is set to 0 again');
                    obj.iter = 1;
                end
            else 
                % for acceleration it is calculated the norm
                acc = sqrt(sum(obj.mobile_obj.Acceleration.^2, 2));
                vel = obj.mobile_obj.Speed;
                lat = obj.mobile_obj.Latitude;
                lon = obj.mobile_obj.Longitude;
            end

            if isempty(acc)
                acc = 0;
            else
                acc = acc - 9.81;
            end

            if isempty(vel)
                vel = 0;
            end

            if isempty(lat)
                lat = 0;
            end

            if isempty(lon)
                lon = 0;
            end

            obj.updateData(acc, vel, lat, lon);

            state = obj.getState();

            [shock, Amax] = obj.isShock();
            if shock
                obj.sendAlert(state, Amax, lat, lon);
            end
            fprintf('State: %s , Shock: %d , Amax: %.2f\r', state, shock, Amax);
            pause(obj.time_step);
        end
        
        function flag = isModeStream(obj)
            flag = false;
            if strcmp(obj.mode, "stream")
                flag = true;
            end
        end

        function flag = isModeOffline(obj)
            flag = false;
            if strcmp(obj.mode, "offline")
                flag = true;
            end
        end

        function updateData(obj, acc, vel, lat, lon)
            % displaces each stored value 1-older time step and updates the most
            % recent value
            obj.acceleration(1:(end - 1)) = obj.acceleration(2:end);
            obj.acceleration(end) = acc;

            if obj.flag_update
                obj.velocity(1:(end - 1)) = obj.velocity(2:end);
                obj.velocity(end) = vel;
                obj.latitude = lat;
                obj.longitude = lon;
            end
        end

        function state = getState(obj)
            % it estimates the current state based on the velocity bia a
            % previously trained KNN
            Vmean = mean(obj.velocity);
            state = char(predict(obj.model_knn, Vmean));
        end

        function [shock, Amax] = isShock(obj)
            % checks if the acceleration has exceeded the maximum threshold
            % shock → Indicates a shock in the acceleration data (boolean)
            % Amax → Maximum acceleration in the samples (m/s2)
            Amax = max(obj.acceleration);
            if Amax > obj.threshold_acceleration
                shock = true;
            else
                shock = false;
            end
        end

        function sendAlert(obj, state, Amax, lat, lon)
            % state → State of the sensor based in its velocity
            % Amax → Maximum acceleration of the shock (m/s2)
            % lat → Latitude (deg)
            % lon → Longitude (deg)
            mapsURL = ['https://www.google.es/maps/dir//' sprintf('%.7f',lat)...
                ',' sprintf('%.7f',lon) '/@' sprintf('%.7f',lat) ',' sprintf('%.7f',lon) ',16z?hl=es'];
            figure('visible', 'off');
            geoplot(lat, lon,'.r','MarkerSize',30)
            geolimits([lat-0.001 lat+0.001],[lon-0.001 lon+0.001])
            geobasemap streets
            saveas(gcf,'map.png')

            msg = ['System detected a <b>' sprintf('%.2f',Amax/9.81) 'g shock</b> while '...
                'user was <b>' state '</b>. Google Maps: ' mapsURL];

            obj.ShockBot.sendPhoto(obj.ChatID, 'photo_file', 'map.png',... % photo
                'usepm', true,... % show progress monitor
                'caption', msg,'parse_mode','HTML'); %caption of photo
        end

        function resetImpl(obj)
            % resets internal data
        end

        function [o1, o2, o3, o4, o5, o6, o7, o8] = getOutputSizeImpl(obj)
            % Return size for each output port
            o1 = [1 1];
            o2 = [1 1];
            o3 = [1 1];
            o4 = [1 1];
            o5 = [1 1];
            o6 = [1 1];
            o7 = [1 1];
            o8 = [1 1];
        end

        function [o1, o2, o3, o4, o5, o6, o7, o8] = getOutputDataTypeImpl(obj)
            % Return data type for each output port
            o1 = "double";
            o2 = "double";
            o3 = "double";
            o4 = "double";
            o5 = "double";
            o6 = "string";
            o7 = "boolean";
            o8 = "double";
        end

        function [o1, o2, o3, o4, o5, o6, o7, o8] = isOutputComplexImpl(obj)
            % Return true for each output port with complex data
            o1 = false;
            o2 = false;
            o3 = false;
            o4 = false;
            o5 = false;
            o6 = false;
            o7 = false;
            o8 = false;
        end

        function [o1, o2, o3, o4, o5, o6, o7, o8] = isOutputFixedSizeImpl(obj)
            % Return true for each output port with fixed size
            o1 = true;
            o2 = true;
            o3 = true;
            o4 = true;
            o5 = true;
            o6 = true;
            o7 = true;
            o8 = true;
        end
    end
end
