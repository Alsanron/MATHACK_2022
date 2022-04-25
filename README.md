# MATHACK_2022
Project of the 2022 MatLab hackaton.
--
Challenge: develop an application using the data obtained with the Matlab Mobile app (i.e. acceleration, speed, position, angular velocity and orientation). The application should be related with at least 1 Sustainable Development Goal.
--
Solution: 
- Simulink model that works either in "offline" mode reading data previously recorded or in "online" mode where that is fetched from the device.
- K-nearest neighbor model that estimates the current state ("IDLE", "WALKING", "RUNNING") based on the speed. The used speed is the mean speed in a user-defined sampling window.
- Acceleration filtering with a custom-designed FIR filter.
- Impact detection based on the acceleration module.

Workflow: the simulink models runs for infinite time, and each time-step it waits the time corresponding to the sensors acquisition frequency (i.e. t_wait = 1/f_acq). Based on the speed the state is estimated, and based on the acceleration it is checked whether an impact has ocurred or not. If it has ocurred, then a notification is sent with the person location and impact acceleration module via telegram.
