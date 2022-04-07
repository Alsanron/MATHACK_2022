function sendAlert(state,Amax,lat,lon)

% state → State of the sensor based in its velocity
% Amax → Maximum acceleration of the shock (m/s2)
% lat → Latitude (deg)
% lon → Longitude (deg)

addpath('telegram_functions')
BotToken = '5171014369:AAGqkyeKK0Zj8EZbPiaH_DrZ_Q7U-b04C9k';
ChatID = '950714104';
ShockBot = telegram_bot(BotToken);

mapsURL = ['https://www.google.es/maps/dir//' sprintf('%.7f',lat)...
    ',' sprintf('%.7f',lon) '/@' sprintf('%.7f',lat) ',' sprintf('%.7f',lon) ',16z?hl=es'];

figure('visible','off');
geoplot(lat,lon,'.r','MarkerSize',30)
geolimits([lat-0.001 lat+0.001],[lon-0.001 lon+0.001])
geobasemap streets
saveas(gcf,'map.png')

msg = ['System detected a <b>' sprintf('%.2f',Amax/9.81) 'g shock</b> while '...
    'user was <b>' state '</b>. Google Maps: ' mapsURL];

ShockBot.sendPhoto(ChatID, 'photo_file', 'map.png',... % photo
    'usepm', true,... % show progress monitor
    'caption', msg,'parse_mode','HTML'); %caption of photo

end